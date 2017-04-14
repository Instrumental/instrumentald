require 'instrumentald/metric_script_executor'
require 'pidly'
require 'toml'
require 'erb'
require 'tempfile'

# We're just using this for mongo URI parsing so require the minimum necessary.
# Unfortunately requiring 'mongo' doesn't work because it tries to load bson
# native extensions, and they aren't built on the target system.
# Also, Mongo::URI doesn't autoload Mongo::Loggable or Mongo::Error, so we need
# to require those as well.
require 'mongo/loggable'
require 'mongo/error'
require 'mongo/uri'

# Mongo has a habit of using BSON::Document whenever they need a hash. Since
# BSON requires native extensions we stub out their options object.
module Mongo::Options
  class Redacted < ::Hash
    def initialize(hash)
      self.merge!(hash)
    end
  end
end

class ServerController < Pidly::Control
  COMMANDS = [:start, :stop, :status, :restart, :clean, :kill, :foreground]
  TELEGRAF_FAILURE_LOGGING_THROTTLE = 100
  TELEGRAF_FAILURE_SLEEP = 1
  DEFAULT_CONFIG_CONTENTS = { 'system' => true }
  TELEGRAF_CONFIG_PATH = File.join(Dir.tmpdir, "instrumentald_telegraf.toml")

  attr_accessor :run_options, :default_options, :pid
  attr_reader :agent

  before_start do
    extra_info = if opts[:daemon]
                   "(#{opts[:pid_location]}), log: #{opts[:log_location]}"
                 end
    puts "Starting daemon process: #{@pid} #{extra_info}"
  end

  start :foreground

  stop do
    puts "Attempting to kill daemon process: #{@pid}"
  end

  error do
    puts 'Error encountered'
  end

  def initialize(options={})
    @run_options = options.delete(:run_options) || {}
    @default_options = options.delete(:default_options) || {}

    secure_protocol = collector_address.split(':').last != '8000'
    @agent = Instrumental::Agent.new(project_token, :collector => collector_address,
                                                    :secure    => secure_protocol)

    super(options)
  end

  def opts
    @opts ||= Hash.new do |hash, key|
      hash[key] = run_options[key.to_sym] || config_file[key.to_s] || default_options[key.to_sym]
    end
  end

  def foreground
    run
  end

  def collector_address
    [opts[:collector], opts[:port]].compact.join(':')
  end

  def user_specified_project_token
    opts[:project_token]
  end

  def config_file
    return @config_file if @config_file
    opts[:config_file] = run_options[:config_file] || default_options[:config_file]
    config_contents = if File.exist?(opts[:config_file])
      TOML::Parser.new(File.read(opts[:config_file])).parsed
    else
      puts "Config file #{opts[:config_file]} not found, using default config"
      DEFAULT_CONFIG_CONTENTS
    end
    if config_contents.is_a?(Hash)
      @config_file = config_contents
    else
      @config_file = {}
    end
  end

  def config_file_project_token
    if config_file_available?
      config_contents = TOML::Parser.new(File.read(opts[:config_file])).parsed
      if config_contents.is_a?(Hash)
        config_contents['project_token']
      end
    end
  rescue Exception => e
    puts "Error loading config file %s: %s" % [opts[:config_file], e.message]
    nil
  end

  def project_token
    (user_specified_project_token || config_file_project_token).to_s.strip
  end


  def report_interval
    opts[:report_interval]
  end

  def hostname
    opts[:hostname]
  end

  def script_location
    opts[:script_location]
  end

  def script_executor
    @executor ||= MetricScriptExecutor.new(script_location)
  end

  def next_run_at(at_moment = Time.now.to_i)
    (at_moment - at_moment % report_interval) + report_interval
  end

  def time_to_sleep
    t = Time.now.to_i
    [next_run_at(t) - t, 0].max
  end

  def config_file_available?
    File.exists?(opts[:config_file])
  end

  def debug?
    !!opts[:debug]
  end

  def system_metrics_config
    return @system_metrics_config_value if @system_metrics_config_value
    config_value  = config_file["system"]
    default_value = ["cpu", "disk", "load", "memory", "network", "swap"]

    @system_metrics_config_value =
      if config_value == true
        default_value
      elsif config_value.is_a?(Array)
        config_value & default_value # intersection of default and config
      else
        []
      end
  end

  def enable_scripts?
    !!opts[:enable_scripts]
  end

  def telegraf_path
    File.expand_path(File.dirname(__FILE__) + "/../telegraf")
  end

  def telegraf_binary_path
    arch, platform = RUBY_PLATFORM.split("-")
    case RUBY_PLATFORM
    when /linux/
      # Support 32-bit?
      "#{telegraf_path}/amd64/telegraf"
    when /darwin/
      "#{telegraf_path}/darwin/telegraf"
    else
      raise "unsupported OS"
    end
  end

  def telegraf_config_path
    TELEGRAF_CONFIG_PATH
  end

  def telegraf_template_config_path
    arch, platform = RUBY_PLATFORM.split("-")
    case RUBY_PLATFORM
    when /linux/
      # Support 32-bit?
      "#{telegraf_path}/telegraf.conf.erb"
    when /darwin/
      "#{telegraf_path}/telegraf.conf.erb"
    else
      raise "unsupported OS"
    end
  end

  def mongodb_configs
    mongodb_servers = Array(config_file["mongodb"])

    mongodb_configs = mongodb_servers.map do |uri|
      begin
        u = Mongo::URI.new(uri)
        u.servers.map do |server|
          creds = "#{u.credentials[:user]}:#{u.credentials[:password]}@" if u.credentials.values.any?
          {:servers => ["mongodb://#{creds}#{server}"], :ssl => u.uri_options[:ssl]}
        end
      rescue Mongo::Error::InvalidURI => ex
        {:servers => [uri]}
      end
    end.flatten.compact
  end

  def process_telegraf_config
    docker_containers  = Array(config_file["docker"])
    memcached_servers  = Array(config_file["memcached"])
    mysql_servers      = Array(config_file["mysql"])
    nginx_servers      = Array(config_file['nginx'])
    postgresql_servers = Array(config_file["postgresql"])
    redis_servers      = Array(config_file["redis"])

    File.open(telegraf_config_path, "w+") do |config|
      result = ERB.new(File.read(telegraf_template_config_path)).result(binding)
      config.write(result)
    end
  end

  def configured_to_collect_any_metrics?
    service_keys = ["docker", "memcached", "mongodb", "mysql", "nginx", "postgresql", "redis"]
    system_metrics_config.any? || (config_file.keys & service_keys).any?
  end

  def run
    puts "instrumentald version #{Instrumentald::VERSION} started at #{Time.now.utc}"
    puts "Collecting stats under the hostname: #{hostname}"

    unless configured_to_collect_any_metrics?
      puts "No system or service metrics configured. Stopping."
      return false
    end

    process_telegraf_config
    run_telegraf

    loop do
      sleep time_to_sleep
      count = 0
      if enable_scripts?
        script_executor.run.each do |(stat, value, time)|
          metric = [hostname, stat].join(".")
          agent.gauge(metric, value, time)
          if debug?
            puts [metric, value].join(":")
          end
          count += 1
        end
      end
      agent.flush
      agent.stop
      if debug?
        puts "Sent #{count} metrics"
      end
    end
  end

  def run_telegraf
    instrumentald_pid = Process.pid
    daemonize do
      $0 = "[Monitor] #{$0}"
      telegraf_pid = nil
      should_run = true

      # monitor thread
      Thread.new do
        # wait for instrumentald to die
        while (Process.kill(0, instrumentald_pid) rescue nil)
          sleep 1
        end

        # if we get here instrumentald has exited and we need to clean up
        should_run = false
        sleep 5 # wait for telegraf to start if it's going to start
        Process.kill("KILL", telegraf_pid)
      end

      if debug?
        puts "starting metrics collector"
        puts "telegraf binary: #{telegraf_binary_path}"
        puts "telegraf config: #{telegraf_config_path}"
      end
      failures = 0
      loop do
        break unless should_run
        begin
          telegraf_pid = fork do
            exec(telegraf_binary_path, "-config", telegraf_config_path)
          end
          Process.detach telegraf_pid
          Process.wait telegraf_pid

          pid, status = Process.wait2(telegraf_pid)

          if !status.success?
            failures += 1
          end
        rescue
          failures += 1
        end
        if (failures - 1) % TELEGRAF_FAILURE_LOGGING_THROTTLE == 0
          puts "telegraf execution failed, #{failures} total failures"
        end
        sleep TELEGRAF_FAILURE_SLEEP # to prevent racing to restart
      end

    end
  end

  # This is how you daemonize in ruby, preventing an orphaned inner process.
  def daemonize(&block)
    temp_pid = fork do
      Process.setsid
      trap 'SIGHUP', 'IGNORE'
      fork do
        yield
      end
    end
    # This prevents the short lived fork from sticking around as a zombie
    Process.detach(temp_pid)
  end

  alias_method :clean, :clean!
end

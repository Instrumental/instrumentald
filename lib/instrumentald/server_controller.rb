require 'instrumentald/metric_script_executor'
require 'pidly'
require 'toml'
require 'erb'
require 'tempfile'

class ServerController < Pidly::Control
  COMMANDS = [:start, :stop, :status, :restart, :clean, :kill, :foreground]
  TELEGRAF_FAILURE_LOGGING_THROTTLE = 100
  TELEGRAF_FAILURE_SLEEP = 1

  attr_accessor :run_options, :default_options, :pid
  attr_reader :current_project_token

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
    @telegraf_config_tempfile = Tempfile.new("instrumentald_telegraf")
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
      puts "Config file #{opts[:config_file]} not found, defaulting to an empty config"
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

  def configured_project_token
    (user_specified_project_token || config_file_project_token).to_s.strip
  end

  def build_agent(key, address, enabled)
    secure_protocol = address.split(':').last != '8000'
    Instrumental::Agent.new(key, collector: address, enabled: enabled, secure: secure_protocol)
  end

  def set_new_agent(key, address)
    key              = key.to_s.strip
    @current_project_token = key
    @agent           = build_agent(key, collector_address, key.size > 0)
  end

  def agent
    if key_has_changed?
      set_new_agent(configured_project_token, collector_address)
    end
    @agent
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

  def enabled?
    agent.enabled
  end

  def debug?
    !!opts[:debug]
  end

  def enable_scripts?
    !!opts[:enable_scripts]
  end

  def key_has_changed?
    current_project_token != configured_project_token
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
    @telegraf_config_tempfile.path
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

  def process_telegraf_config
    instrumental_project_token = configured_project_token

    docker_containers  = Array(config_file["docker"])
    memcached_servers  = Array(config_file["memcached"])
    mongodb_servers    = Array(config_file["mongodb"])
    mysql_servers      = Array(config_file["mysql"])
    nginx_servers      = Array(config_file['nginx'])
    postgresql_servers = Array(config_file["postgresql"])
    redis_servers      = Array(config_file["redis"])
    system_metrics     = config_file["system"] || true

    File.open(telegraf_config_path, "w+") do |config|
      result = ERB.new(File.read(telegraf_template_config_path)).result(binding)
      config.write(result)
    end
  end

  def run
    puts "instrumentald version #{Instrumentald::VERSION} started at #{Time.now.utc}"
    puts "Collecting stats under the hostname: #{hostname}"

    process_telegraf_config
    run_telegraf

    loop do
      sleep time_to_sleep
      if enabled?
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

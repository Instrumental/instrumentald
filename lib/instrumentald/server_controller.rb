require 'instrumentald/metric_script_executor'
require 'instrumentald/system_inspector'
require 'pidly'
require 'toml'
require 'erb'
require 'tempfile'

class ServerController < Pidly::Control
  COMMANDS = [:start, :stop, :status, :restart, :clean, :kill, :foreground]
  TELEGRAF_FAILURE_LOGGING_THROTTLE = 100
  TELEGRAF_FAILURE_SLEEP = 1

  attr_accessor :run_options, :pid
  attr_reader :current_api_key

  before_start do
    extra_info = if run_options[:daemon]
                   "(#{run_options[:pid_location]}), log: #{run_options[:log_location]}"
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
    @telegraf_config_tempfile = Tempfile.new("instrumentald_telegraph")
    super(options)
  end

  def foreground
    run
  end

  def collector_address
    [run_options[:collector], run_options[:port]].compact.join(':')
  end

  def user_specified_api_key
    run_options[:api_key]
  end

  def config_file
    return @config_file if @config_file
    config_contents = if File.exist?(run_options[:config_file])
      TOML::Parser.new(File.read(run_options[:config_file])).parsed
    else
      puts "Config file #{run_options[:config_file]} not found, defaulting to an empty config"
    end
    if config_contents.is_a?(Hash)
      @config_file = config_contents
    else
      @config_file = {}
    end
  end

  def config_file_api_key
    if config_file_available?
      config_contents = TOML::Parser.new(File.read(run_options[:config_file])).parsed
      if config_contents.is_a?(Hash)
        config_contents['api_key']
      end
    end
  rescue Exception => e
    puts "Error loading config file %s: %s" % [run_options[:config_file], e.message]
    nil
  end

  def configured_api_key
    (user_specified_api_key || config_file_api_key).to_s.strip
  end

  def build_agent(key, address, enabled)
    secure_protocol = address.split(':').last != '8000'
    Instrumental::Agent.new(key, collector: address, enabled: enabled, secure: secure_protocol)
  end

  def set_new_agent(key, address)
    key              = key.to_s.strip
    @current_api_key = key
    @agent           = build_agent(key, collector_address, key.size > 0)
  end

  def agent
    if key_has_changed?
      set_new_agent(configured_api_key, collector_address)
    end
    @agent
  end

  def report_interval
    run_options[:report_interval]
  end

  def hostname
    run_options[:hostname]
  end

  def script_location
    run_options[:script_location]
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
    File.exists?(run_options[:config_file])
  end

  def enabled?
    agent.enabled
  end

  def debug?
    !!run_options[:debug]
  end

  def enable_scripts?
    !!run_options[:enable_scripts]
  end

  def key_has_changed?
    current_api_key != configured_api_key
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
    when /(windows|win32|mingw)/
      "#{telegraf_path}/win32/telegraf.exe"
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
    when /(windows|win32|mingw)/
      # TODO: get a windows config in place
      "#{telegraf_path}/win32/telegraf.conf.erb"
    else
      raise "unsupported OS"
    end
  end

  def process_telegraf_config
    instrumental_api_key = configured_api_key
    redis_servers = config_file['redis']
    File.open(telegraf_config_path, "w+") do |config|
      result = ERB.new(File.read(telegraf_template_config_path)).result(binding)
      config.write(result)
    end
  end

  def run
    puts "instrumentald version #{Instrumental::VERSION} started at #{Time.now.utc}"
    puts "Collecting stats under the hostname: #{hostname}"

    process_telegraf_config
    Thread.new do
      if debug?
        puts "starting metrics collector"
        puts "telegraf binary: #{telegraf_binary_path}"
        puts "telegraf config: #{telegraf_config_path}"
      end
      failures = 0
      loop do
        begin
          success = system(telegraf_binary_path, "-config", telegraf_config_path)
          if !success
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

    loop do
      sleep time_to_sleep
      if enabled?
        inspector = SystemInspector.new
        inspector.load_all
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

  alias_method :clean, :clean!
end

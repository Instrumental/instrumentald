require 'pidly'
require 'instrumental_tools/metric_script_executor'
require 'instrumental_tools/system_inspector'

class ServerController < Pidly::Control
  COMMANDS = [:start, :stop, :status, :restart, :clean, :kill, :foreground]

  attr_accessor :run_options, :pid

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

  def self.run(options)
    agent = Instrumental::Agent.new(options[:api_key], :collector => [options[:collector], options[:port]].compact.join(':'))
    puts "instrument_server version #{Instrumental::Tools::VERSION} started at #{Time.now.utc}"
    puts "Collecting stats under the hostname: #{options[:hostname]}"
    report_interval = options[:report_interval]
    custom_metrics  = MetricScriptExecutor.new(options[:script_location])
    loop do
      t = Time.now.to_i
      next_run_at = (t - t % report_interval) + report_interval
      sleep [next_run_at - t, 0].max
      inspector = SystemInspector.new
      inspector.load_all
      count = 0
      inspector.gauges.each do |stat, value|
        metric = "#{options[:hostname]}.#{stat}"
        agent.gauge(metric, value)
        if options[:debug]
          puts [metric, value].join(":")
        end
        count += 1
      end
      custom_metrics.run.each do |(stat, value, time)|
        metric = "#{options[:hostname]}.#{stat}"
        agent.gauge(metric, value, time)
        if options[:debug]
          puts [metric, value].join(":")
        end
        count += 1
      end
      puts "Sent #{count} metrics"
    end
  end

  def initialize(options={})
    @run_options = options.delete(:run_options) || {}
    super(options)
  end

  def foreground
    self.class.run(run_options)
  end

  alias_method :clean, :clean!
end

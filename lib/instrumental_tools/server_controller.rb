require 'pidly'
require 'instrumental_tools/system_inspector'

class ServerController < Pidly::Control
  COMMANDS = [:start, :stop, :status, :restart, :clean, :kill]

  attr_accessor :run_options, :pid

  before_start do
    extra_info = if run_options[:daemon]
                   "(#{run_options[:pid_location]}), log: #{run_options[:log_location]}"
                 end
    puts "Starting daemon process: #{@pid} #{extra_info}"
  end

  start :run

  stop do
    puts "Attempting to kill daemon process: #{@pid}"
  end

  error do
    puts 'Error encountered'
  end

  def self.run(options)
    agent = Instrumental::Agent.new(options[:api_key], :collector => [options[:collector], options[:port]].compact.join(':'))
    puts "insrument_server version #{Instrumental::Tools::VERSION} started at #{Time.now.utc}"
    puts "Collecting stats under the hostname: #{options[:hostname]}"
    report_interval = options[:report_interval]
    loop do
      t = Time.now.to_i
      next_run_at = (t - t % report_interval) + report_interval
      sleep [next_run_at - t, 0].max
      inspector = SystemInspector.new
      inspector.load_all
      inspector.gauges.each do |stat, value|
        agent.gauge("#{options[:hostname]}.#{stat}", value)
      end
      # agent.increment("#{host}.#{stat}", delta)
    end
  end

  def initialize(options={})
    @run_options = options.delete(:run_options) || {}
    super(options)
  end

  def run
    self.class.run(run_options)
  end

  alias_method :clean, :clean!
end

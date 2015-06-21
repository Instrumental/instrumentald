class SystemInspector
  TYPES = [:gauges, :incrementors]
  attr_accessor *TYPES

  def self.memory
    @memory ||= Memory.new
  end

  def initialize
    @gauges = {}
    @incrementors = {}
    @platform =
      case RUBY_PLATFORM
      when /linux/
        require "instrumental_tools/system_inspector/linux"
        SystemInspector::Linux
      when /darwin/
        require "instrumental_tools/system_inspector/osx"
        SystemInspector::OSX
      when /(windows|win32|mingw)/
        require "instrumental_tools/system_inspector/win32"
        SystemInspector::Win32
      else
        raise "unsupported OS"
      end
  end

  def self.command_missing(command, section)
    puts "Command #{command} not found. Metrics for #{section} will not be collected."
  end

  def self.command_present?(command, section)
    `which #{command}`.length > 0 || command_missing(command, section)
  end

  def load_all
    self.class.memory.cycle

    load @platform.load_cpu
    load @platform.load_memory
    load @platform.load_disks
    load @platform.load_filesystem
  end

  def load(stats)
    @gauges.merge!(stats[:gauges] || {})
  end

  class Memory
    attr_reader :past_values, :current_values

    def initialize
      @past_values = {}
      @current_values = {}
    end

    def store(attribute, value)
      @current_values[attribute] = value
    end

    def retrieve(attribute)
      @past_values[attribute]
    end

    def cycle
      @past_values = @current_values
      @current_values = {}
    end
  end
end

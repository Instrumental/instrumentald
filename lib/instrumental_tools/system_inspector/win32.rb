require "wmi-lite"

# TODO: Remove before merge
class Instrumental::Agent
  def wait_exceptions
    classes = [Errno::EAGAIN]
    if defined?(IO::EAGAINWaitReadable)
      classes << IO::EAGAINWaitReadable
    end
    if defined?(IO::EWOULDBLOCKWaitReadable)
      classes << IO::EWOULDBLOCKWaitReadable
    end
    if defined?(IO::WaitReadable)
      classes << IO::WaitReadable
    end
    classes
  end


  def test_connection
    begin
      # In the case where the socket is an OpenSSL::SSL::SSLSocket,
      # on Ruby 1.8.6, 1.8.7 or 1.9.1, read_nonblock does not exist,
      # and so the case of testing socket liveliness via a nonblocking
      # read that catches a wait condition won't work.
      #
      # We grab the SSL socket's underlying IO object and perform the
      # non blocking read there in order to ensure the socket is still
      # valid
      if @socket.respond_to?(:read_nonblock)
        @socket.read_nonblock(1)
      elsif @socket.respond_to?(:io)
        @socket.io.read_nonblock(1)
      end
    rescue *wait_exceptions
      # noop
    end
  end
end

class SystemInspector
  module Win32

    def self.wmi
      @wmi ||= WmiLite::Wmi.new
    end

    def self.sanitize(name)
      name.gsub(/[^a-z0-9\-\_]/i, "_").gsub(/(\A_+|_+\Z)/, "")
    end

    def self.load_cpu
      cpus      = wmi.query("SELECT PercentProcessorTime, PercentUserTime, PercentPrivilegedTime, PercentIdleTime, PercentInterruptTime FROM Win32_PerfFormattedData_PerfOS_Processor")
      cpu_zero  = cpus[0]
      sysresult = wmi.query("SELECT ProcessorQueueLength FROM Win32_PerfFormattedData_PerfOS_System")
      sys_stat  = sysresult[0]
      {
        :gauges => {
          "cpu.in_use"                  => cpu_zero["PercentProcessorTime"].to_f,
          "cpu.user"                    => cpu_zero["PercentUserTime"].to_f,
          "cpu.system"                  => cpu_zero["PercentPrivilegedTime"].to_f,
          "cpu.idle"                    => cpu_zero["PercentIdleTime"].to_f,
          "cpu.iowait"                  => cpu_zero["PercentInterruptTime"].to_f,
          "load.processor_queue_length" => sys_stat["ProcessorQueueLength"].to_i
        }
      }
    end

    def self.load_memory
      memresults    = wmi.query("SELECT AvailableMBytes,CacheBytes FROM Win32_PerfFormattedData_PerfOS_Memory")
      physmemory    = wmi.query("SELECT Capacity FROM Win32_PhysicalMemory WHERE PoweredOn != false").reduce(0) { |memo, h| memo + h["Capacity"].to_f }
      swapmemory    = wmi.query("SELECT Name, PercentUsage FROM Win32_PerfFormattedData_PerfOS_PagingFile")
      physmemory_mb = physmemory / 1024.0 / 1024.0
      mainmemory = memresults[0]
      avail_mb   = mainmemory["AvailableMBytes"].to_f
      used_mb    = physmemory_mb - avail_mb
      cached_mb  = mainmemory["CacheBytes"].to_f / 1024.0 / 1024.0
      free_perc  = avail_mb / physmemory_mb
      if free_perc.nan? || free_perc.infinite?
        free_perc = 0
      end
      free_perc *= 100.0
      memory_stats = {
        "memory.used_mb"      => used_mb,
        "memory.free_mb"      => avail_mb,
        "memory.cached_mb"    => cached_mb,
        "memory.free_percent" => free_perc
      }
      swapmemory.each do |result|
        formatted_name = sanitize(result["Name"])
        used = result["PercentUsage"].to_f
        memory_stats["swap.#{formatted_name}.free_percent"] = 100 - used
        memory_stats["swap.#{formatted_name}.used_percent"] = used
      end
      { :gauges => memory_stats }
    end

    def self.load_disks
      logical_disks = wmi.query("SELECT Name,FreeSpace,Size FROM Win32_LogicalDisk")
      disk_stats = logical_disks.reduce({}) do |memo, disk|
        name    = sanitize(disk["Name"])
        free_mb = disk["FreeSpace"].to_f / 1024.0 / 1024.0
        size_mb = disk["Size"].to_f / 1024.0 / 1024.0
        avail_perc = free_mb / size_mb
        if avail_perc.nan? || avail_perc.infinite?
          avail_perc = 0
        end
        avail_perc *= 100.0
        memo.merge({
          "disk.#{name}.total_mb"            => size_mb,
          "disk.#{name}.used_mb"             => size_mb - free_mb,
          "disk.#{name}.available_mb"        => free_mb,
          "disk.#{name}.available_percent"   => avail_perc
        })
      end
      { :gauges => disk_stats }
    end

    def self.load_filesystem
      {}
    end
  end
end

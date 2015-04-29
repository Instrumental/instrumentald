class SystemInspector
  module Linux
    def self.load_cpu
      output = { :gauges => {} }
      output[:gauges].merge!(cpu)
      output[:gauges].merge!(loadavg)
      output
    end

    def self.cpu_file
      "/proc/stat"
    end

    def self.load_file
      "/proc/loadavg"
    end

    def self.disk_file
      "/proc/diskstats"
    end

    def self.mount_file
      "/proc/mounts"
    end

    def self.open_files_file
      "/proc/sys/fs/file-nr"
    end

    def self.memory_file
      "/proc/meminfo"
    end

    def self.cpu
      categories = [:user, :nice, :system, :idle, :iowait]
      values     = File.read(cpu_file).lines.grep(/\Acpu[^0-9]/).slice(1, 5).map { |v| v.to_f }
      SystemInspector.memory.store(:cpu_values, values.dup)
      if previous_values = SystemInspector.memory.retrieve(:cpu_values)
        index = -1
        values.collect! { |value| (previous_values[index += 1] - value).abs }
      end
      data   = Hash[*categories.zip(values).flatten]
      total  = values.inject { |memo, value| memo + value }

      output = {}
      if previous_values
        data.each do |category, value|
          output["cpu.#{category}"] = value / total * 100
        end
      end
      output["cpu.in_use"] = 100 - data[:idle] / total * 100
      output
    end

    def self.loadavg
      min_1, min_5, min_15 = File.read(load_file).split
      {
        'load.1min'  => min_1.to_f,
        'load.5min'  => min_5.to_f,
        'load.15min' => min_15.to_f
      }
    end

    def self.load_memory
      output = { :gauges => {} }
      if File.exists?(memory_file)
        output[:gauges].merge!(memory)
      end
      output
    end

    def self.memory
      memory_stats = Hash[File.read(memory_file).lines.map { |line| line.chomp.strip.split(/:\s+/) }.reject { |l| l.size != 2 } ]
      total        = memory_stats["MemTotal"].to_f
      free         = memory_stats["MemFree"].to_f
      used         = free - total
      buffers      = memory_stats["Buffers"].to_f
      cached       = memory_stats["Cached"].to_f
      swaptotal    = memory_stats["SwapTotal"].to_f
      swapfree     = memory_stats["SwapFree"].to_f
      swapused     = swapfree - swaptotal

      stats_to_record = {
        'memory.used_mb'      => used / 1024,
        'memory.free_mb'      => free / 1024,
        'memory.buffers_mb'   => buffers / 1024,
        'memory.cached_mb'    => cached / 1024,
        'memory.free_percent' => (free / total) * 100,

      }

      if swaptotal > 0
        stats_to_record.merge!({
                                 'swap.used_mb'        => swapused / 1024,
                                 'swap.free_mb'        => swapfree / 1024,
                                 'swap.free_percent'   => (swapfree / swaptotal) * 100
                               })
      end

      stats_to_record
    end

    def self.load_disks
      output = { :gauges => {} }
      if SystemInspector.command_present?('df', 'disk storage')
        output[:gauges].merge!(disk_storage)
      end
      if File.exists?(mount_file) && File.exists?(disk_file)
        output[:gauges].merge!(disk_io)
      end
      output
    end

    def self.disk_storage
      output = {}
      `df -Pka`.lines.each do |line|
        device, total, used, available, capacity, mount = line.chomp.split
        if device == "tmpfs"
          names = ["tmpfs_#{mount.gsub(/[^[:alnum:]]/, "_")}".gsub(/_+/, "_")]
        elsif device =~ %r{/dev/}
          names = [File.basename(device)]
        else
          next
        end
        names << 'root' if mount == '/'
        names.each do |name|
          output["disk.#{name}.total_mb"]          = total.to_f / 1024
          output["disk.#{name}.used_mb"]           = used.to_f / 1024
          output["disk.#{name}.available_mb"]      = available.to_f / 1024
          output["disk.#{name}.available_percent"] = available.to_f / total.to_f * 100
        end
      end
      output
    end

    def self.disk_io
      output          = {}
      mounted_devices = File.read(mount_file).lines.grep(/\A\/dev\/(\w+)/) { File.realpath($1) }
      diskstats_lines = File.read(disk_file).lines.map(&:split).select { |values| mounted_devices.include?(values.first) }
      entries         = diskstats_lines.map do |values|
                          entry               = {}
                          entry[:time]        = Time.now
                          entry[:device]      = values[2]
                          entry[:utilization] = values[12].to_f
                          SystemInspector.memory.store("disk_stats_#{entry[:device]}".to_sym, entry)
                        end

      entries.each do |entry|
        if previous_entry = SystemInspector.memory.retrieve("disk_stats_#{entry[:device]}".to_sym)
          time_delta                                           = (entry[:time] - previous_entry[:time]) * 1000
          utilization_delta                                    = entry[:utilization] - previous_entry[:utilization]
          output["disk.#{entry[:device]}.percent_utilization"] = utilization_delta / time_delta * 100
        end
      end
      output
    end

    def self.load_filesystem
      output = { :gauges => {} }
      if File.exists?(open_files_file)
        output[:gauges].merge!(filesystem)
      end
      output
    end

    def self.filesystem
      allocated, unused, max = File.read(open_files_file).split.map(&:to_i)
      open_files             = allocated - unused
      {
        'filesystem.open_files'         => open_files,
        'filesystem.max_open_files'     => max,
        'filesystem.open_files_pct_max' => (open_files.to_f / max.to_f) * 100
      }
    end
  end
end

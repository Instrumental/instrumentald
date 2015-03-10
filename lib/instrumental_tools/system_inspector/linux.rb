class SystemInspector
  module Linux
    def self.load_cpu
      output = { :gauges => {} }
      output[:gauges].merge!(cpu)
      output[:gauges].merge!(loadavg)
      output
    end

    def self.cpu
      categories = [:user, :nice, :system, :idle, :iowait]
      values     = `cat /proc/stat | grep cpu[^0-9]`.chomp.split(/\s+/).slice(1, 5).map { |v| v.to_f }
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
      min_1, min_5, min_15 = `cat /proc/loadavg`.split(/\s+/)
      {
        'load.1min'  => min_1.to_f,
        'load.5min'  => min_5.to_f,
        'load.15min' => min_15.to_f
      }
    end

    def self.load_memory
      output = { :gauges => {} }
      if SystemInspector.command_present?('free', 'memory')
        output[:gauges].merge!(memory)
      end
      if SystemInspector.command_present?('free', 'swap')
        output[:gauges].merge!(swap)
      end
      output
    end

    def self.memory
      _, total, used, free, shared, buffers, cached = `free -k -o | grep Mem`.chomp.split(/\s+/)
      {
        'memory.used_mb'      => used.to_f / 1024,
        'memory.free_mb'      => free.to_f / 1024,
        'memory.buffers_mb'   => buffers.to_f / 1024,
        'memory.cached_mb'    => cached.to_f / 1024,
        'memory.free_percent' => (free.to_f / total.to_f) * 100
      }
    end

    def self.swap
      _, total, used, free = `free -k -o | grep Swap`.chomp.split(/\s+/)
      return {} if total.to_i == 0
      {
        'swap.used_mb'      => used.to_f / 1024,
        'swap.free_mb'      => free.to_f / 1024,
        'swap.free_percent' => (free.to_f / total.to_f) * 100
      }
    end

    def self.load_disks
      output = { :gauges => {} }
      if SystemInspector.command_present?('df', 'disk storage')
        output[:gauges].merge!(disk_storage)
      end
      if SystemInspector.command_present?('mount', 'disk IO')
        output[:gauges].merge!(disk_io)
      end
      output
    end

    def self.disk_storage
      output = {}
      `df -Pka`.split("\n").each do |line|
        device, total, used, available, capacity, mount = line.split(/\s+/)
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
      mounted_devices = `mount`.split("\n").grep(/^\/dev\/(\w+)/) { $1 }
      diskstats_lines = `cat /proc/diskstats`.split("\n").grep(/#{mounted_devices.join('|')}/)
      entries         = diskstats_lines.map do |line|
                          values              = line.split
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
      if SystemInspector.command_present?('sysctl', 'filesystem')
        output[:gauges].merge!(filesystem)
      end
      output
    end

    def self.filesystem
      allocated, unused, max = `sysctl fs.file-nr`.split[-3..-1].map { |v| v.to_i }
      open_files             = allocated - unused
      {
        'filesystem.open_files'         => open_files,
        'filesystem.max_open_files'     => max,
        'filesystem.open_files_pct_max' => (open_files.to_f / max.to_f) * 100
      }
    end
  end
end

class SystemInspector
  module OSX
    def self.load_cpu
      output = { :gauges => {} }
      if SystemInspector.command_present?('top', 'CPU')
        output[:gauges].merge!(top)
      end
      output
    end

    def self.top
      lines     = []
      processes = date = load = cpu = nil

      IO.popen('top -l 1 -n 0') do |top|
        processes = top.gets.split(': ')[1]
        date      = top.gets
        load      = top.gets.split(': ')[1]
        cpu       = top.gets.split(': ')[1]
      end

      user, system, idle                       = cpu.split(", ").map { |v| v.to_f }
      load1, load5, load15                     = load.split(", ").map { |v| v.to_f }
      total, running, stuck, sleeping, threads = processes.split(", ").map { |v| v.to_i }

      {
        'cpu.user'           => user,
        'cpu.system'         => system,
        'cpu.idle'           => idle,
        'load.1min'          => load1,
        'load.5min'          => load5,
        'load.15min'         => load15,
        'processes.total'    => total,
        'processes.running'  => running,
        'processes.stuck'    => stuck,
        'processes.sleeping' => sleeping,
        'threads'            => threads,
      }
    end

    def self.load_memory
      # TODO: swap
      output = { :gauges => {} }
      if SystemInspector.command_present?('vm_stat', 'memory')
        output[:gauges].merge!(vm_stat)
      end
      output
    end

    def self.vm_stat
      header, *rows = `vm_stat`.split("\n")
      page_size     = header.match(/page size of (\d+) bytes/)[1].to_i
      sections      = ["free", "active", "inactive", "wired", "speculative", "wired down"]
      output        = {}
      total         = 0.0

      rows.each do |row|
        if match = row.match(/Pages (.*):\s+(\d+)\./)
          section, value = match[1, 2]
          if sections.include?(section)
            value                                         = value.to_f * page_size / 1024 / 1024
            output["memory.#{section.gsub(' ', '_')}_mb"] = value
            total                                        += value
          end
        end
      end
      output["memory.free_percent"] = output["memory.free_mb"] / total * 100 # TODO: verify
      output
    end

    def self.load_disks
      output = { :gauges => {} }
      if SystemInspector.command_present?('df', 'disk')
        output[:gauges].merge!(df)
      end
      output
    end

    def self.df
      output = {}
      `df -k`.split("\n").grep(%r{^/dev/}).each do |line|

        device, total, used, available, capacity, mount = line.split(/\s+/)

        names = [File.basename(device)]
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

    def self.netstat(interface = 'en1')
      # mostly functional network io stats
      headers, *lines = `netstat -ibI #{interface}`.split("\n").map { |l| l.split(/\s+/) } # FIXME: vulnerability?
      headers         = headers.map { |h| h.downcase }
      lines.each do |line|
        if !line[3].include?(':')
          return Hash[headers.zip(line)]
        end
      end
    end

    def self.load_filesystem
      {}
    end
  end
end

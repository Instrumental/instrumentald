require 'benchmark'

class MetricScriptExecutor

  attr_reader :directory, :previous, :last_ran_at

  def initialize(directory)
    @directory   = directory
    @previous    = {}
  end

  def can_execute_file?(path)
    stat = File::Stat.new(path)
    stat.executable? && stat.owned? && ((stat.mode & 0xFFF) ^ 0O700) == 0
  end

  def run
    process_to_output = {}
    if File.directory?(directory)
      current = Dir[File.join(directory, "*")].map do |path|
        full_path = File.expand_path(path)
        if can_execute_file?(path)
          stdin_r,  stdin_w  = IO.pipe
          stdout_r, stdout_w = IO.pipe
          stderr_r, stderr_w = IO.pipe

          previous_status, previous_time, previous_output = previous[full_path]

          stdin_w.write(previous_output || "")
          stdin_w.close


          cmd = [full_path, (previous_time || 0).to_i, (previous_status && previous_status.to_i)].compact.join(" ")

          pid = Process.spawn(cmd,
                              :chdir => File.dirname(full_path),
                              :in    => stdin_r,
                              :out   => stdout_w,
                              :err   => stderr_w)

          exit_status = nil
          exec_time   = Benchmark.realtime do
                          pid, exit_status = Process.wait2(pid)
                        end

          if exec_time > 1.0
            puts "[SLOW SCRIPT] Time to execute process #{full_path} took #{exec_time} seconds"
          end

          [stdin_r, stdout_w, stderr_w].each(&:close)

          output = stdout_r.read.to_s.chomp

          stderr = stderr_r.read.to_s.chomp
          unless stderr.empty?
            puts "[STDERR] #{full_path} (PID:#{pid}) [#{Time.now.to_s}]:: #{stderr}"
          end

          [stdout_r, stderr_r].each(&:close)

          [full_path, [exit_status, Time.now, output]]
        else
          if !File.directory?(full_path)
            uid  = Process.uid
            user = Etc.getpwuid(uid).name
            puts "[INFO] Cannot execute #{full_path}, must be executable and only readable/writable by #{user}/#{uid}"
          end
          [full_path, []]
        end
      end
      process_to_output = Hash[current]
      @previous         = process_to_output
    else
      puts "Directory #{directory} has gone away, not scanning for metric scripts."
    end
    process_to_output.flat_map do |path, (status, time, output)|
      if status && status.success?
        prefix = File.basename(path).split(".")[0..-2].join(".").gsub(/[^a-z0-9\-\_\.]/i, "_")
        output.split(/[\r\n]+/)                                                                # each line
          .map    { |line| line.split(/\s+/) }                                                 # split by whitespace
          .select { |data| (2..3).include?(data.size)  }                                       # and only valid name value time? pairs
          .map    { |(name, value, specific_time)| [[prefix, name].join("."), value.to_f, specific_time || time] } # with value coerced to a float
      end
    end.compact
  end

end

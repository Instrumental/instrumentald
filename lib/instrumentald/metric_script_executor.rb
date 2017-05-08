require 'benchmark'

class MetricScriptExecutor

  attr_reader :directory, :previous, :last_ran_at

  def initialize(directory)
    @directory   = directory
    @previous    = {}
  end

  def can_execute_file?(path)
    stat = File::Stat.new(path)
    stat.executable? && file_is_owner_only?(stat)
  end

  def can_execute_in_directory?(directory)
    stat = File::Stat.new(directory)
    stat.directory? && file_is_owner_only?(stat)
  end

  def file_is_owner_only?(file_stat)
    file_stat.owned? && ((file_stat.mode & 0xFFF) ^ 0O700) == 0
  end

  def print_executable_warning(path)
    uid  = Process.uid
    user = Etc.getpwuid(uid).name
    puts "[INFO] Cannot execute #{path}, must exist, be executable and only readable/writable by #{user}/#{uid}"
  end

  def print_executable_in_directory_warning(directory)
    puts "Directory #{directory} has gone away or does not have the correct permissions (0700), not scanning for metric scripts."
  end

  def execute_custom_script(full_path)
    stdin_r,  stdin_w  = IO.pipe
    stdout_r, stdout_w = IO.pipe
    stderr_r, stderr_w = IO.pipe

    previous_status, previous_time, previous_output = previous[full_path]

    stdin_w.write(previous_output || "")
    stdin_w.close


    cmd = [full_path, (previous_time || 0).to_i, (previous_status && previous_status.to_i)].compact.map(&:to_s)
    pid = Process.spawn(*cmd,
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
  end

  def run
    process_to_output = {}
    if can_execute_in_directory?(directory)
      current = Dir[File.join(directory, "*")].map do |path|
        full_path = File.expand_path(path)
        if can_execute_file?(path)
          execute_custom_script(full_path)
        else
          if !File.directory?(full_path)
            print_executable_warning(full_path)
          end
          [full_path, []]
        end
      end
      process_to_output = Hash[current]
      @previous         = process_to_output
    else
      print_executable_in_directory_warning(directory)
    end
    process_to_output.flat_map do |path, (status, time, output)|
      if status && status.success?
        prefix = File.basename(path).split(".")[0..-2].join(".").gsub(/[^\d\w\-\_\.]/i, "_")
        output.lines                                      # each line
          .map    { |line| line.chomp.split }             # split by whitespace
          .select { |data| (2..3).include?(data.size)  }  # and only valid name value time? pairs
          .map    { |(name, value, specific_time)| [[prefix, name].join("."), value.to_f, (specific_time || time).to_i] } # with value coerced to a float
      end
    end.compact
  end

end

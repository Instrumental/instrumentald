#!/usr/bin/env ruby

stdout_r, stdout_w = IO.pipe
pid                = Process.spawn("docker ps", :err => STDERR, :out => stdout_w)
_, exit_status     = Process.wait2(pid)

stdout_w.close

if !exit_status.success?
  STDERR.puts stdout_r.read
  exit 1
end

header, *content = stdout_r.read.chomp.split(/[\r\n]+/)
stdout_r.close

header            = header.split(/\s{2,}/)
content           = content.map { |line| line.split(/\s{2,}/) }
docker_containers = content.map { |data| Hash[header.zip(data)] }
cpu_info          = "/sys/fs/cgroup/cpuacct/"
mem_info          = "/sys/fs/cgroup/memory/"

previous_run_time = ARGV[0].to_i
current_time      = Time.now.to_i
run_interval      = (current_time - previous_run_time).to_f
previously_ran    = previous_run_time > 0
previous_values   = {}

if previously_ran
  previous_output = STDIN.read.chomp.split(/[\n\r]+/)
                                    .map { |line| line.split(/\s+/) }
                                    .map { |(name, value, _)| [name, value.to_f] }
  previous_values = Hash[previous_output]
end

all_stats = docker_containers.map do |container|
  stats = {}
  container_name = Array(container["NAMES"].to_s.split(",")).first || container["CONTAINER ID"][0..7]
  Dir[File.join(cpu_info, "**", container["CONTAINER ID"] + "*", "cpuacct.stat")].each do |file|

    cpu_stats = Hash[File.read(file).split(/[\r\n]+/).map { |line| line.split(/\s+/) }]

    %w{system user}.each do |stat|
      output_stat = [container_name, stat + "_total"].join(".")
      stats[output_stat] = cpu_stats[stat]
      if previously_ran
        time_over_interval                      = (cpu_stats[stat].to_f - previous_values[output_stat]) / run_interval
        stats[[container_name, stat].join(".")] = time_over_interval
      end
    end
  end
  Dir[File.join(mem_info, "**", container["CONTAINER ID"] + "*", "memory.stat")].each do |file|
    mem_stats = Hash[File.read(file).split(/[\r\n]+/).map { |line| line.split(/\s+/) }]

    %w{cache rss mapped_file swap}.each do |stat|
      stats[[container_name, stat + "_mb"].join(".")] = mem_stats[stat].to_i / 1024.0 / 1024.0
    end
  end
  stats
end

puts "running %s" % docker_containers.size
all_stats.each do |row|
  row.each do |metric, value|
    puts [metric, value].join(" ")
  end
end

if !previously_ran
  exit 1
end

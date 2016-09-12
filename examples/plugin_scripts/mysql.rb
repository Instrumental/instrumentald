#!/usr/bin/env ruby

# Ensure your instrumentald process runs with these environment variables set,
# or replace with your own.

MYSQL_HOST              = ENV["MYSQL_HOST"] || "localhost"
MYSQL_PORT              = ENV["MYSQL_PORT"] || 3306
MYSQL_USER              = ENV["MYSQL_USER"]
MYSQL_DEFAULTS_FILE     = ENV["MYSQL_DEFAULTS_FILE"]
MYSQL_PASSWORD          = ENV["MYSQL_PASSWORD"]

RATE_METRICS_TO_INSPECT = %w{queries bytes_sent bytes_received connections slow_queries}
CANARY_METRIC           = "queries"

env  = {}
args = []
if MYSQL_DEFAULTS_FILE.to_s.size > 0
  args << "--defaults-file=%s" % MYSQL_DEFAULTS_FILE
else
  env = { "MYSQL_PWD" => MYSQL_PASSWORD }
end
args += [
          "-N",
          "-B",
          "-e",
          "SHOW GLOBAL STATUS"
        ]
if MYSQL_USER
  args += ["--user", MYSQL_USER]
end
if MYSQL_HOST
  args += ["--host", MYSQL_HOST]
end
if MYSQL_PORT
  args += ["--port", MYSQL_PORT]
end

stdout_r, stdout_w = IO.pipe

pid = Process.spawn(env, "mysql", *args.map(&:to_s), :out => stdout_w, :err => STDERR)

pid, exit_status = Process.wait2(pid)

stdout_w.close

previous_run_time = ARGV[0].to_i
current_time      = Time.now.to_i
run_interval      = (current_time - previous_run_time).to_f
previously_ran    = previous_run_time > 0
previous_values   = {}

if previously_ran
  previous_output = STDIN.read.chomp.each_line.map
                                    .map { |line| line.split }
                                    .map { |(name, value, _)| [name, value.to_f] }
  previous_values = Hash[previous_output]
end

if !exit_status.success?
  exit exit_status.to_i
else
  output = stdout_r.read.lines                                         # each line
                        .map { |line| line.chomp.split }              # split by space characters
                        .map { |(name, value, _)| [name.downcase, value.to_f] } # with values coerced to floats
  stats  = Hash[output]
  if (stats[CANARY_METRIC] < previous_values[CANARY_METRIC].to_i) || previous_values[CANARY_METRIC].nil?
    # The server has restarted, don't trust previous values for calculating difference
    previously_ran = false
  end
  if previously_ran
    RATE_METRICS_TO_INSPECT.each do |metric|
      stats["%s_per_second" % metric] = (stats[metric] - previous_values[metric]) / run_interval
    end
  end
  RATE_METRICS_TO_INSPECT.each do |metric|
    puts [metric, stats[metric]].join(" ")
    per_second_metric = "%s_per_second" % metric
    per_second        = stats[per_second_metric]
    if per_second
      puts [per_second_metric, per_second].join(" ")
    end
  end
  if previously_ran
    exit 0
  else
    exit 1
  end
end

#!/usr/bin/env ruby

# Ensure your instrument_server process runs with these environment variables set,
# or replace with your own.

HOST      = ENV["MYSQL_HOST"]
PORT      = ENV["MYSQL_PORT"] || 3306
USER      = ENV["MYSQL_USER"]

# It is preferable to use a .cnf file, see http://dev.mysql.com/doc/refman/5.0/en/password-security-user.html
OPTS_FILE = ENV["MYSQL_CNF_FILE"]

# Only specify a password here if you cannot use the .cnf file method
PASSWORD  = ENV["MYSQL_PASSWORD"]

RATE_METRICS_TO_INSPECT = %w{Queries Bytes_sent Bytes_received Connections Slow_queries}
CANARY_METRIC           = "Queries"

require 'shellwords'

env = {}
cmd = "mysql -N -B -e 'SHOW GLOBAL STATUS' --user %s --host %s --port %s" % [USER, HOST, PORT].map { |arg| Shellwords.escape(arg) }

if OPTS_FILE.to_s.size > 0
  cmd += " --defaults-file %s" % Shellwords.escape(OPTS_FILE)
else
  env = { "MYSQL_PWD" => PASSWORD }
end

stdout_r, stdout_w = IO.pipe

pid = Process.spawn(env, cmd, :out => stdout_w, :err => STDERR)

pid, exit_status = Process.wait2(pid)

stdout_w.close

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

if exit_status.success?
  output = stdout_r.read.split(/[\n\r]+/)                               # each line
                        .map { |line| line.split(/\s+/) }               # split by space characters
                        .map { |(name, value, _)| [name, value.to_f] }  # with values coerced to floats
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
else
  exit exit_status.to_i
end

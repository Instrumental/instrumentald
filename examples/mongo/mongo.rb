#!/usr/bin/env ruby

require 'shellwords'
require 'yaml'

MONGO_HOST           = ENV["MONGO_HOST"] || "127.0.0.1"
MONGO_PORT           = ENV["MONGO_PORT"] || 27017
MONGO_USER           = ENV["MONGO_USER"]
MONGO_PWD            = ENV["MONGO_PASSWORD"]
MONGO_AUTH_MECHANISM = ENV["MONGO_AUTH_MECHANISM"]
MONGO_AUTH_DB        = ENV["MONGO_AUTH_DB"]


CMDS                 = %w{mongotop mongostat}

outputs = CMDS.map do |cmd|
  cmd_with_arguments = "%s --json -n 1 --host %s --port %s" % [cmd, Shellwords.escape(MONGO_HOST), Shellwords.escape(MONGO_PORT)]
  if MONGO_USER
    cmd_with_arguments += " --user %s" % Shellwords.escape(MONGO_USER)
  end
  if MONGO_PWD
    cmd_with_arguments += " --password %s" % Shellwords.escape(MONGO_PWD)
  end
  if MONGO_AUTH_DB
    cmd_with_arguments += " --authenticationDatabase %s" % Shellwords.escape(MONGO_AUTH_DB)
  end
  if MONGO_AUTH_MECHANISM
    cmd_with_arguments += " --authenticationMechanism %s" % Shellwords.escape(MONGO_AUTH_MECHANISM)
  end
  stdout_r, stdout_w = IO.pipe
  pid                = Process.spawn(cmd_with_arguments, :err => STDERR, :out => stdout_w)
  _, exit_status     = Process.wait2(pid)
  stdout_w.close
  output             = stdout_r.read.chomp
  if !exit_status.success?
    STDERR.puts output
    exit 1
  end
  [cmd, output]
end

cmd_to_output = Hash[outputs]

if (output = cmd_to_output["mongotop"])
  stats = YAML.load(output)
  (stats["totals"] || {}).each do |collection, totals|
    stat = "mongotop.%s" % collection.gsub(/[^a-z0-9\-\_]/i, "_")
    %w{total read write}.each do |metric|
      puts "%s.%s_ms %s" % [stat, metric, totals[metric]["time"]]
    end
  end
end

if (output = cmd_to_output["mongostat"])
  stats = YAML.load(output)
  stats.each do |host, metrics|
    stat = "mongostat.%s" % host.gsub(/[^a-z0-9\-\_]/i, "_")
    ["conn", "delete", "faults", "flushes", "getmore", ["idx miss %", "idx_miss_pct"], "insert", "mapped", "netIn", "netOut", "query", "res", "update", "vsize"].each do |metric|
      name, value = case metric
                    when Array
                      key, output_key = metric
                      [output_key, metrics[key]]
                    else
                      [metric, metrics[metric]]
                    end
      if value =~ /\A([\d\.]+)(b|k|M|G)\Z/
        value = case $2
                when "b"
                  $1.to_f / 1024.0 / 1024.0
                when "k"
                  $1.to_f / 1024.0
                when "M"
                  $1.to_f
                when "G"
                  $1.to_f * 1024.0
                end
        name += "_mb"
      end
      value     = value.to_s.gsub(/[^\d\.]/, "")
      puts "%s.%s %s" % [stat, name, value]
    end
  end
end

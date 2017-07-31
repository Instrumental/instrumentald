# coding: utf-8
require 'serverspec'

details = {}

set :backend, :exec
details = {
  check_owner:      true,
  config:           "/etc/instrumentald.toml",
  has_pid:          true,
  pid_path:         "/opt/instrumentald/instrumentald.pid",
  owner:            "nobody",
  service_name:     "instrumentald",
  log_path:         "/opt/instrumentald/instrumentald.log",
}


describe service(details[:service_name]) do
  it { should be_enabled }
  it { should be_running }
end

# "should be_running" doesn't seem to work, probably because the init.d script
# has an exit status of 0 when it is NOT running.
describe command('sudo /etc/init.d/instrumentald status') do
  its(:stdout) { should match /"instrumentald" is running/ }
end

if details[:has_pid]
  describe file(details[:pid_path]) do
    it { should be_file }
    if details[:check_owner]
      it { should be_owned_by(details[:owner]) }
    end
  end
end

describe file(details[:config]) do
  it { should be_file }
  if details[:check_owner]
    it { should be_owned_by(details[:owner]) }
  end
end

describe file(details[:log_path]) do
  it { should be_file }
  if details[:check_owner]
    it { should be_owned_by(details[:owner]) }
  end
  # it { should contain 'ServerName www.example.jp' }
  process_start_log_line = 'instrumentald\sversion\s.*\sstarted.*'
  its(:content) do
    should match %r{
      #{process_start_log_line}        # find the last process start
      (?!#{process_start_log_line})    # (it is because there isn't a start later)

      # Then check the log of just the last run
      Attempting\sconnection\sto\soutput:\sinstrumental
    }mx
  end
end

describe command("timeout 5s /opt/instrumentald/instrumentald -e -s /tmp/instrumentald_scripts/ -u nobody -l /tmp/instrumentald_script_test.log --report-interval 1 2>&1") do
  its(:stdout) do
    should include(<<~CONF)
      test_script.test_script.metric:1.0
    CONF
    should include(<<~CONF)
      test_script_no_extension.test_script.metric:1.0
    CONF
  end
end

describe file("/tmp/instrumentald_scripts/log") do
  its(:content) do
    should match /instrumentald test script success/
  end
end

wait_for_telegraf_conf = %Q{for i in `seq 1 20`; do ls -tr /tmp/instrumentald_telegraf* 2>&1 && break; echo "waiting"; sleep 1; done}
cat_telegraf_conf = %Q{cat `(ls -tr /tmp/instrumentald_telegraf* || echo "no_tmp_telegraf_files_found") | tail -n 1` 2>&1}
describe command("#{wait_for_telegraf_conf}; #{cat_telegraf_conf}") do

  # Plain, one host, mongodb scheme
  its(:stdout) do
    should include(<<~CONF)
      [[inputs.mongodb]]
      #   ## An array of URI to gather stats about. Specify an ip or hostname
      #   ## with optional port add password. ie,
      #   ##   mongodb://user:auth_key@10.10.3.30:27017,
      #   ##   mongodb://10.10.3.33:18832,
      #   ##   10.0.0.1:10000, etc.
        servers = ["mongodb://localhost:27017"]
        tagexclude = ["state", "host"]


    CONF
  end

  # Multi-host, mongodb scheme
  its(:stdout) do
    should include(<<~CONF)
      [[inputs.mongodb]]
      #   ## An array of URI to gather stats about. Specify an ip or hostname
      #   ## with optional port add password. ie,
      #   ##   mongodb://user:auth_key@10.10.3.30:27017,
      #   ##   mongodb://10.10.3.33:18832,
      #   ##   10.0.0.1:10000, etc.
        servers = ["mongodb://instrumentald-atlas-test:<PASSWORD>@cluster0-shard-00-00-uvipm.mongodb.net:27017", "mongodb://instrumentald-atlas-test:<PASSWORD>@cluster0-shard-00-01-uvipm.mongodb.net:27017", "mongodb://instrumentald-atlas-test:<PASSWORD>@cluster0-shard-00-02-uvipm.mongodb.net:27017"]
        tagexclude = ["state", "host"]

        [inputs.mongodb.ssl]
        enabled = true


    CONF
  end

  # No-scheme, one host
  its(:stdout) do
    should include(<<~CONF)
      [[inputs.mongodb]]
      #   ## An array of URI to gather stats about. Specify an ip or hostname
      #   ## with optional port add password. ie,
      #   ##   mongodb://user:auth_key@10.10.3.30:27017,
      #   ##   mongodb://10.10.3.33:18832,
      #   ##   10.0.0.1:10000, etc.
        servers = ["test-no-scheme.com:27017"]
        tagexclude = ["state", "host"]


    CONF
  end

end

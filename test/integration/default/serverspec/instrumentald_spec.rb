require 'serverspec'

details = {}

set :backend, :exec
details = {
  check_owner:      true,
  config:           "/etc/instrumentald.toml",
  has_pid:          true,
  pid_path:         "/opt/instrumentald/instrumentald.pid",
  owner:            "nobody",
  service_name:     "instrumentald"
}


describe service(details[:service_name]) do
  it { should be_enabled }
  it { should be_running }
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

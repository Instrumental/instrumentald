require 'serverspec'

details = {}

if RUBY_PLATFORM =~ /(win|mswin|mingw)/i
  set :backend, :cmd
  set :os, :family => 'windows'
  details = {
    check_executable: false,
    check_owner:      false,
    config:           "c:\\Program Files (x86)\\Instrumental Tools\\etc\\instrumental.yml",
    executable:       "c:\\Program Files (x86)\\Instrumental Tools\\instrument_server.bat",
    has_pid:          false
  }
else
  set :backend, :exec
  details = {
    check_executable: true,
    check_owner:      true,
    config:           "/etc/instrumental.yml",
    executable:       "/opt/instrumental-tools/instrument_server",
    has_pid:          true,
    pid_path:         "/opt/instrumental-tools/instrument_server.pid",
    owner:            "nobody"
  }
end


describe file(details[:executable]) do
  it { should be_file }
  if details[:check_executable]
    it { should be_executable }
  end
end

describe service('instrument_server') do
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

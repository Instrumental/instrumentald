require 'serverspec'

set :backend, :exec


describe package('instrumental-tools') do
  it { should be_installed }
end

describe service('instrument_server') do
  it { should be_enabled }
  it { should be_running }
end

describe file('/opt/instrumental-tools/instrument_server.pid') do
  it { should be_file }
  it { should be_owned_by('nobody') }
end

describe file('/etc/instrumental.yml') do
  it { should be_file }
  it { should be_owned_by('nobody') }
end

describe process('ruby') do
  it         { should be_running }
  its(:user) { should eq 'nobody' }
  its(:args) { should match /instrument_server/ }
end

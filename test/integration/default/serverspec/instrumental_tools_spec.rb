require 'serverspec'

set :backend, :exec


describe package('instrumental-tools') do
  it { should be_installed }
end

describe service('instrument_server') do
  it { should be_enabled }
  it { should be_running }
end

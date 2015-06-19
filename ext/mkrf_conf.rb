require 'rubygems'
require 'rubygems/command.rb'
require 'rubygems/dependency_installer.rb'

begin
  Gem::Command.build_args = ARGV
rescue NoMethodError
end

inst = Gem::DependencyInstaller.new

begin
  if RUBY_PLATFORM =~ /(win32|windows|mingw)/i
    inst.install "wmi-lite", "~> 1.0.0"
  end
rescue
  exit(1)
end

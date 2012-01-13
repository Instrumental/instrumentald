$: << "./lib"
require 'instrumental_tools/version'

Gem::Specification.new do |s|
  s.name        = "instrumental_tools"
  s.version     = Instrumental::Tools::VERSION
  s.authors     = ["Elijah Miller", "Christopher Zelenak", "Kristopher Chambers", "Matthew Hassfurder"]
  s.email       = ["support@instrumentalapp.com"]
  s.homepage    = "http://github.com/fastestforward/instrumental_tools"
  s.summary     = %q{Command line tools for Instrumental}
  s.description = %q{A collection of scripts useful for monitoring servers and services with Instrumental (instrumentalapp.com)}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_runtime_dependency(%q<json>, [">=0"])
  s.add_runtime_dependency(%q<instrumental_agent>, [">=0.5"])
  s.add_runtime_dependency(%q<pidly>, [">=0.1.3"])
  s.add_development_dependency(%q<rake>, [">=0"])
end

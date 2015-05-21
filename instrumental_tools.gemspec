$: << "./lib"
require 'find'
require 'instrumental_tools/version'

gitignore = Array(File.exists?(".gitignore") ? File.read(".gitignore").split("\n") : []) + [".git", ".gitignore"]
all_files = []

Find.find(".") do |path|
  scrubbed_path = path.gsub(/\A\.\//, "")
  if gitignore.any? { |glob| File.fnmatch(glob, scrubbed_path) }
    Find.prune
  else
    if !File.directory?(scrubbed_path)
      all_files << scrubbed_path
    end
  end
end

test_files = all_files.select { |path| path =~ /\A(test|spec|features)\//i }
bin_files  = all_files.select { |path| path.index("bin") == 0 }.map { |path| File.basename(path) }

Gem::Specification.new do |s|
  s.name        = "instrumental_tools"
  s.version     = Instrumental::Tools::VERSION
  s.authors     = ["Expected Behavior"]
  s.email       = ["support@instrumentalapp.com"]
  s.homepage    = "http://github.com/expectedbehavior/instrumental_tools"
  s.summary     = %q{Command line tools for Instrumental}
  s.description = %q{A collection of scripts useful for monitoring servers and services with Instrumental (instrumentalapp.com)}
  s.licenses    = ["MIT"]

  s.files         = all_files
  s.test_files    = test_files
  s.executables   = bin_files
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 1.9'

  s.add_runtime_dependency(%q<instrumental_agent>, [">=0.12.6"])
  s.add_runtime_dependency(%q<pidly>, [">=0.1.3"])
  s.add_development_dependency(%q<rake>, [">=0"])
  s.add_development_dependency(%q<fpm>, [">=1.3.3"])
  s.add_development_dependency(%q<package_cloud>, [">=0"])
  s.add_development_dependency(%q<test-kitchen>, [">=0"])
  s.add_development_dependency(%q<kitchen-vagrant>, [">=0"])
  s.add_development_dependency(%q<kitchen-puppet>, [">=0"])
  s.add_development_dependency(%q<berkshelf>, [">=0"])
  s.add_development_dependency(%q<librarian-puppet>, [">=0"])
  s.add_development_dependency(%q<puppet>, [">=0"])
  s.add_development_dependency(%q<serverspec>, [">=0"])
end

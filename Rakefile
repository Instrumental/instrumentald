
require 'bundler/gem_tasks'
require 'etc'
require 'fileutils'
require 'socket'
require 'yaml'

PACKAGE_CATEGORY       = "Utilities"
PACKAGECLOUD_REPO      = "expectedbehavior/instrumental"
CONFIG_DIR             = "conf"
CONFIG_DEST            = "/etc/"

GEMSPEC                = Bundler::GemHelper.instance.gemspec
SPEC_PATH              = Bundler::GemHelper.instance.spec_path
PACKAGE_NAME           = GEMSPEC.name.gsub("_", "-") # Debian packages cannot include _ in name
VERSION                = GEMSPEC.version
TRAVELING_RUBY_VERSION = "20150210-2.1.5"
TRAVELING_RUBY_FILE    = "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-%s.tar.gz"
DEST_DIR               = File.join("/opt/", PACKAGE_NAME)
PACKAGE_OUTPUT_NAME    = [PACKAGE_NAME, VERSION].join("_")
LICENSE                = Array(GEMSPEC.licenses).first || "None"
VENDOR                 = Array(GEMSPEC.authors).first || Etc.getlogin
MAINTAINER             = Array(GEMSPEC.email).first || [Etc.getlogin, Socket.gethostname].join("@")
HOMEPAGE               = GEMSPEC.homepage || ""
DESCRIPTION            = GEMSPEC.description || ""
SUPPORTED_DISTROS      = {
                           'deb' => ['ubuntu/precise', 'ubuntu/lucid', 'ubuntu/trusty', 'ubuntu/utopic', 'debian/lenny', 'debian/squeeze', 'debian/wheezy'],
                           'rpm' => ['el/5', 'el/6', 'el/7']
                         }
EXTRA_ARGS             = {
                           'deb' => '--deb-init debian/instrument_server --after-install debian/after-install.sh --before-remove debian/before-remove.sh --after-remove debian/after-remove.sh --deb-user nobody --deb-group nogroup',
                           'rpm' => '--rpm-init rpm/instrument_server --after-install rpm/after-install.sh --before-remove rpm/before-remove.sh --after-remove rpm/after-remove.sh --rpm-user nobody --rpm-group nobody --rpm-os linux --rpm-attr "-,nobody,nobody:/opt/instrumental-tools/" --directories /opt/instrumental-tools/'
                         }


WRAPPER_SCRIPT_SHELL = <<-EOSCRIPT
#!/bin/bash
set -e

# Figure out where this script is located.
SELFDIR="`dirname \"$0\"`"
SELFDIR="`cd \"$SELFDIR\" && pwd`"

# Tell Bundler where the Gemfile and gems are.
export BUNDLE_GEMFILE="$SELFDIR/lib/vendor/Gemfile"
unset BUNDLE_IGNORE_CONFIG

# Run the actual app using the bundled Ruby interpreter.
exec "$SELFDIR/lib/ruby/bin/ruby" -rbundler/setup "$SELFDIR/lib/app/%s" "$@"
EOSCRIPT

WRAPPER_SCRIPT_BAT = <<-EOSCRIPT
@echo off

:: Tell Bundler where the Gemfile and gems are.
set "BUNDLE_GEMFILE=%%~dp0\\lib\\vendor\\Gemfile"
set BUNDLE_IGNORE_CONFIG=

:: Run the actual app using the bundled Ruby interpreter, with Bundler activated.
@"%%~dp0\\lib\\ruby\\bin\\ruby.bat" -rbundler/setup "%%~dp0\\lib\\app\\%s" %%*
EOSCRIPT

ARCHITECTURES          = {
                           'linux-x86' => {
                             runtime:      TRAVELING_RUBY_FILE % "linux-x86",
                             arch:         "i386",
                             packages:     %w{deb rpm},
                             platform:     "linux",
                             packagecloud: true,
                             wrapper:      WRAPPER_SCRIPT_SHELL,
                             separator:    '/'
                            },
                           'linux-x86_64' => {
                             runtime:      TRAVELING_RUBY_FILE % "linux-x86_64",
                             arch:         "amd64",
                             packages:     %w{deb rpm},
                             platform:     "linux",
                             packagecloud: true,
                             wrapper:      WRAPPER_SCRIPT_SHELL,
                             separator:    '/'
                           },
                           'osx' => {
                             runtime:      TRAVELING_RUBY_FILE % "osx",
                             arch:         "x86_64",
                             packages:     [],
                             platform:     "darwin",
                             packagecloud: false,
                             wrapper:      WRAPPER_SCRIPT_SHELL,
                             separator:    '/'
                           },
                           'win32' => {
                             runtime:         TRAVELING_RUBY_FILE % "win32",
                             packages:        [],
                             packagecloud:    false,
                             compress_format: 'zip',
                             wrapper:         WRAPPER_SCRIPT_BAT,
                             separator:       '\\',
                             extension:       '.bat'
                           }
                         }




BUNDLE_CONFIG = <<-EOBUNDLECONFIG
BUNDLE_PATH: .
BUNDLE_WITHOUT: development
BUNDLE_DISABLE_SHARED_GEMS: '1'
EOBUNDLECONFIG


desc "Package your app"
task :package => ARCHITECTURES.map { |name, _| "package:%s" % name }

ARCHITECTURES.each do |name, config|
  namespace "package" do

    has_packaging = Array(config[:packages]).size > 0

    if has_packaging
      desc "Package your app for %s" % name
      task name => ["%s:package" % name]
    else
      desc "Package your app for %s" % name
      task name => ["%s:compress" % name]
    end

    namespace name do
      desc "Create a compressed package for %s" % name
      task "compress" do
        task("package:bundle_install").invoke(name.to_sym)
        task(config[:runtime]).invoke
        create_compressed_package(create_directory_bundle(name, config[:wrapper], config[:separator], config[:extension]), config[:compress_format])
      end

      if has_packaging
        desc "Create packages (%s) for %s" % [config[:packages].join(","), name]
        task "package" do
          task("package:bundle_install").invoke(name.to_sym)
          task(config[:runtime]).invoke
          create_packages(create_compressed_package(create_directory_bundle(name, config[:wrapper], config[:separator], config[:extension], DEST_DIR), config[:compress_format]), config[:platform], config[:arch], config[:packages])
        end
      end

      if config[:packagecloud]
        namespace "packagecloud" do
          desc "Push packages (%s) to package_cloud" % config[:packages].join(",")
          task "push" do
            packages     = create_packages(create_compressed_package(create_directory_bundle(name, config[:wrapper], config[:separator], config[:extension], DEST_DIR), config[:compress_format]), config[:platform], config[:arch], config[:packages])
            by_extension = packages.group_by { |path| File.extname(path)[1..-1] }
            by_extension.each do |extension, files|
              distros = SUPPORTED_DISTROS[extension]
              distros.each do |distro|
                repo = File.join(PACKAGECLOUD_REPO, distro)
                files.each do |file|
                  yank_cmd = "package_cloud yank %s %s" % [repo, file]
                  puts yank_cmd
                  system(yank_cmd)
                  sh "package_cloud push %s %s" % [repo, file]
                end
              end
            end
          end
        end
      end

    end
  end


  file config[:runtime] do
    download_runtime(name)
  end
end

namespace "package" do

  desc "Install gems to local directory"
  task :bundle_install, [:platform] do |t, args|
    if RUBY_VERSION !~ /^2\.1\./
      abort "You can only 'bundle install' using Ruby 2.1, because that's what Traveling Ruby uses."
    end

    tmp_package_dir = File.join("packaging", "tmp")
    spec_path       = SPEC_PATH
    cache_dir       = File.join("packaging", "vendor", "*", "*", "cache", "*")

    sh "rm -rf %s"                     % tmp_package_dir
    sh "mkdir -p %s"                   % tmp_package_dir
    sh "cp %s Gemfile Gemfile.lock %s" % [spec_path, tmp_package_dir]

    GEMSPEC.require_paths.each do |path|
      sh "ln -sf %s %s" % [File.expand_path(path), tmp_package_dir]
    end



    env = if args[:platform] == :win32
            "INSTALL_WINDOWS=1"
          else
            ""
          end
    Bundler.with_clean_env do
      sh "cd %s && env BUNDLE_IGNORE_CONFIG=1 #{env} bundle install --path ../vendor --without development" % tmp_package_dir
    end

    sh "rm -rf %s" % tmp_package_dir
    sh "rm -f %s"  % cache_dir
  end

end

def create_packages(directory, platform, architecture, package_formats)
  Array(package_formats).map { |pkg| create_package(directory, pkg, platform, architecture) }
end

def create_package(tarball, pkg, platform, architecture)
  output_name = [[PACKAGE_OUTPUT_NAME, architecture].join("_"), pkg].join(".")
  extra_args  = EXTRA_ARGS[pkg] || ""
  sh "fpm -s tar -t %s -f -n %s -v %s -a %s --license \"%s\" --vendor \"%s\" --maintainer \"%s\" --url \"%s\" --description \"%s\" --category \"%s\" --config-files %s -C %s -p %s %s %s" % [pkg, PACKAGE_NAME, VERSION, architecture, LICENSE, VENDOR, MAINTAINER, HOMEPAGE, DESCRIPTION, PACKAGE_CATEGORY, CONFIG_DEST, File.basename(tarball, ".tar.gz"), output_name, extra_args, tarball]
  output_name
end

def create_directory_bundle(target, wrapper_script, separator, extension = nil, prefix = nil)
  package_dir         = [PACKAGE_NAME, VERSION, target].join("_")
  prefixed_dir        = if prefix
                          File.join(package_dir, prefix)
                        else
                          package_dir
                        end
  lib_dir             = File.join(prefixed_dir, "lib")
  config_dest_dir     = File.join(package_dir, CONFIG_DEST)
  app_dir             = File.join(lib_dir, "app")
  ruby_dir            = File.join(lib_dir, "ruby")
  dest_vendor_dir     = File.join(lib_dir, "vendor")
  vendor_dir          = File.join("packaging", "vendor")
  traveling_ruby_file = "packaging/traveling-ruby-%s-%s.tar.gz" % [TRAVELING_RUBY_VERSION, target]
  spec_path           = SPEC_PATH
  bundle_dir          = File.join(dest_vendor_dir, ".bundle")


  sh "rm -rf %s"   % package_dir
  sh "mkdir %s"    % package_dir
  sh "mkdir -p %s" % prefixed_dir
  sh "mkdir -p %s" % config_dest_dir
  sh "mkdir -p %s" % app_dir

  GEMSPEC.files.each do |file|
    destination_dir = File.join(app_dir, File.dirname(file))
    FileUtils.mkdir_p(destination_dir)

    sh "cp %s %s" % [file, destination_dir]
  end

  Dir[File.join(CONFIG_DIR, "*")].each do |file|
    sh "cp %s %s" % [file, config_dest_dir]
  end

  sh "mkdir %s"          % ruby_dir
  sh "tar -xzf %s -C %s" % [traveling_ruby_file, ruby_dir]

  GEMSPEC.executables.each do |file|
    destination = File.join(prefixed_dir, file + extension.to_s)

    bin_path = "bin" + separator + file
    File.open(destination, "w") { |f| f.write(wrapper_script % bin_path) }

    sh "chmod +x %s" % destination
  end

  sh "cp -pR %s %s"                  % [vendor_dir, lib_dir]
  sh "cp %s Gemfile Gemfile.lock %s" % [spec_path, dest_vendor_dir]


  GEMSPEC.require_paths.select { |path| path !~ /.rbenv/ }.each do |path|
    sh "ln -sf ../app/%s %s" % [path, File.join(dest_vendor_dir, path)]
  end

  FileUtils.mkdir_p(bundle_dir)
  File.open(File.join(bundle_dir, "config"), "w") { |f| f.write(BUNDLE_CONFIG) }
  package_dir
end

def create_compressed_package(package_dir, format = 'tar.gz')
  format ||= 'tar.gz'
  case format
  when 'tar.gz'
    gzip_file   = "%s.tar.gz" % package_dir

    sh "tar -czf %s %s" % [gzip_file, package_dir]

    gzip_file
  when 'zip'
    zip_file    = "%s.zip" % package_dir

    sh "zip -r %s %s" % [zip_file, package_dir]

    zip_file
  else
    raise StandardError.new("Format %s is not supported" % format)
  end
end

def download_runtime(target)
  traveling_ruby_name     = ["traveling-ruby", TRAVELING_RUBY_VERSION, target].join("-")
  traveling_ruby_file     = "%s.tar.gz" % traveling_ruby_name
  traveling_ruby_releases = "http://d6r77u77i8pq3.cloudfront.net/releases"
  traveling_ruby_url      = File.join(traveling_ruby_releases, traveling_ruby_file)

  sh "cd packaging && curl -L -O --fail %s" % traveling_ruby_url
end

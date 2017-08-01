$: << "./lib"

require 'etc'
require 'fileutils'
require 'find'
require 'socket'
require 'tempfile'
require 'find'
require 'instrumentald/version'

task :default => 'build'

PACKAGE_CATEGORY       = "Utilities"
PACKAGECLOUD_REPO      = "expectedbehavior/instrumental"
CONFIG_DIR             = "conf"
CONFIG_DEST            = "/etc/"

PACKAGE_NAME           = 'instrumentald'
VERSION                = Instrumentald::VERSION
TRAVELING_RUBY_VERSION = "20150517-2.1.6"
TRAVELING_RUBY_FILE    = "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-%s.tar.gz"
DEST_DIR               = File.join("/opt/", PACKAGE_NAME)
PACKAGE_OUTPUT_NAME    = [PACKAGE_NAME, VERSION].join("_")
LICENSE                = "MIT"
VENDOR                 = "Expected Behavior"
MAINTAINER             = "support@instrumentalapp.com"
HOMEPAGE               = "http://github.com/instrumental/instrumentald"
DESCRIPTION            = "Instrumental is an application monitoring platform built for developers who want a better understanding of their production software. Powerful tools, like the Instrumental Query Language, combined with an exploration-focused interface allow you to get real answers to complex questions, in real-time. InstrumentalD provides server and service monitoring through the instrumentald daemon. It provides strong data reliability at high scale."
SUPPORTED_DISTROS      = {
  'deb' => [
    'ubuntu/precise', # 12.04
    'ubuntu/trusty',  # 14.04
    'ubuntu/xenial',  # 16.04
    'debian/wheezy',  # 7.0
    'debian/jessie'   # 8.0
  ],
  'rpm' => [
    'el/5',
    'el/6',
    'el/7'
  ]
}
EXTRA_ARGS             = {
  'deb' => '--deb-init debian/instrumentald --deb-systemd systemd/instrumentald.service --after-install debian/after-install.sh --before-remove debian/before-remove.sh --after-remove debian/after-remove.sh --deb-user nobody --deb-group nogroup',
  'rpm' => '--rpm-init rpm/instrumentald --after-install rpm/after-install.sh --before-remove rpm/before-remove.sh --after-remove rpm/after-remove.sh --rpm-user nobody --rpm-group nobody --rpm-os linux --rpm-attr "-,nobody,nobody:/opt/instrumentald/" --directories /opt/instrumentald/',
  "osxpkg" => "--osxpkg-identifier-prefix com.instrumentalapp --name instrumentald --after-install osx/after-install.sh --osxpkg-dont-obsolete /etc/instrumentald.toml", # remove doesn't exist on osx
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

ARCHITECTURES          = {
                           'linux-x86' => {
                             runtime:      TRAVELING_RUBY_FILE % "linux-x86",
                             arch:         "i386",
                             packages:     %w{deb rpm},
                             platform:     "linux",
                             packagecloud: true,
                             wrapper:      WRAPPER_SCRIPT_SHELL,
                             separator:    '/',
                             package_from_compressed: true,
                             dest_dir:     DEST_DIR
                            },
                           'linux-x86_64' => {
                             runtime:      TRAVELING_RUBY_FILE % "linux-x86_64",
                             arch:         "amd64",
                             packages:     %w{deb rpm},
                             platform:     "linux",
                             packagecloud: true,
                             wrapper:      WRAPPER_SCRIPT_SHELL,
                             separator:    '/',
                             package_from_compressed: true,
                             dest_dir:     DEST_DIR
                           },
                           'osx' => {
                             runtime:      TRAVELING_RUBY_FILE % "osx",
                             arch:         "x86_64",
                             packages:     ["osxpkg"],
                             platform:     "darwin",
                             packagecloud: false,
                             wrapper:      WRAPPER_SCRIPT_SHELL,
                             separator:    '/',
                             package_from_compressed: true,
                             dest_dir:     DEST_DIR
                           }
                         }




BUNDLE_CONFIG = <<-EOBUNDLECONFIG
BUNDLE_PATH: .
BUNDLE_WITHOUT: development
BUNDLE_DISABLE_SHARED_GEMS: '1'
EOBUNDLECONFIG


desc "Package"
task :package => ARCHITECTURES.map { |name, _| "package:%s" % name }

ARCHITECTURES.each do |name, config|
  namespace "package" do

    has_packaging = Array(config[:packages]).size > 0

    if has_packaging
      desc "Package for %s" % name
      task name => ["%s:package" % name]
    else
      desc "Package for %s" % name
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
          destination = create_directory_bundle(name, config[:wrapper], config[:separator], config[:extension], config[:dest_dir])
          if config[:package_from_compressed]
            destination = create_compressed_package(destination, config[:compress_format])
          end
          create_packages(destination, config[:platform], config[:arch], config[:packages])
        end
      end

      if config[:packagecloud]
        namespace "packagecloud" do
          desc "Push packages (%s) to packagecloud.io" % config[:packages].join(",")
          task "release" do
            puts "\e[32mReleasing v%s for %s...\e[0m" % [VERSION, name]
            puts "\e[32mYanking any existing v%s packages for %s before releasing new ones...\e[0m" % [VERSION, name]
            task("package:%s:packagecloud:yank" % name).invoke
            destination = create_directory_bundle(name, config[:wrapper], config[:separator], config[:extension], config[:dest_dir])
            if config[:package_from_compressed]
              destination = create_compressed_package(destination, config[:compress_format])
            end
            packages     = create_packages(destination, config[:platform], config[:arch], config[:packages])
            by_extension = packages.group_by { |path| File.extname(path)[1..-1] }
            by_extension.each do |extension, files|
              distros = SUPPORTED_DISTROS[extension]
              distros.each do |distro|
                repo = File.join(PACKAGECLOUD_REPO, distro)
                files.each do |file|
                  sh %Q{package_cloud push "%s" "%s"} % [repo, file]
                end
              end
            end
          end

          desc "Yank version %s %s packages (%s) from packagecloud.io, set version=<version> to yank a different version." % [VERSION, name, config[:packages].join(",")]
          task "yank" do
            packages     = config[:packages]
            architecture = config[:arch]
            version      = ENV['version'] || VERSION

            packages.each do |extension|
              SUPPORTED_DISTROS[extension].each do |distro|
                package  = [PACKAGE_NAME, version].join("_")
                filename = [[package, architecture].join("_"), extension].join(".")
                repo     = File.join(PACKAGECLOUD_REPO, distro)
                yank_cmd = %Q{package_cloud yank "%s" "%s"} % [repo, filename]

                if distro =~ /el/
                  # Packagecloud adds a "-1" as the "release" version
                  # http://www.rpm.org/max-rpm/ch-rpm-file-format.html
                  # changing instrumentald_0.0.3_i386.rpm
                  # into     instrumentald-0.0.3-1.i386.rpm
                  yank_cmd = yank_cmd.sub(/_#{Regexp.escape(version.to_s)}_/, "-#{version.to_s}-1.")
                  # and      instrumentald_0.0.3_amd64.rpm
                  # into     instrumentald-0.0.3-1.x86_64.rpm
                  yank_cmd = yank_cmd.sub(/\.amd64/, ".x86_64")
                end

                puts "\e[32mYanking %s for %s...\e[0m" % [filename, distro]
                system(yank_cmd)
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

  desc "Release built packages"
  task :release => ARCHITECTURES.map { |name, config|
    "package:#{name}:packagecloud:release" if config[:packagecloud]
  }.compact

  namespace :osx do
    namespace :homebrew do
      desc "Print homebrew formula information"
      task :print_formula_info do
        url = "https://github.com/Instrumental/instrumentald/releases/download/v#{VERSION}/instrumentald_#{VERSION}_osx.tar.gz"
        package_data = File.read(File.expand_path("../instrumentald_#{VERSION}_osx.tar.gz", __FILE__))
        sha256 = Digest::SHA256.hexdigest(package_data)

        puts <<-STR
          url: #{url}
          version: #{VERSION}
          sha256: #{sha256}

          Checking GitHub release...
        STR

        release_hash = begin
          Digest::SHA256.hexdigest(URI.parse(url).read)
        rescue => ex
          puts "#{ex.inspect}\n#{ex.backtrace.join("\n")}\n\n"
          raise "Error: the osx package that homebrew would reference doesn't appear to exist. You may need to upload files to the github release."
        end
        unless Digest::SHA256.hexdigest(URI.parse(url).read) == sha256
          raise "Error: the osx package that homebrew would reference appears to exist on github, but doesn't match the expected hash. Have you yanked and re-published and need to update the github releases?"
        end
        puts "GitHub release looks good."
      end
    end
  end


  desc "Yank all packages for v%s, set version=<version> to yank a different version." % VERSION
  task :yank => ARCHITECTURES.map { |name, config|
    "package:#{name}:packagecloud:yank" if config[:packagecloud]
  }.compact

  desc "Install gems to local directory"
  task :bundle_install, [:platform] do |t, args|
    if RUBY_VERSION !~ /^2\.1\./
      abort "You can only 'bundle install' using Ruby 2.1, because that's what Traveling Ruby uses."
    end

    tmp_package_dir = File.join("packaging", "tmp")
    cache_dir       = File.join("packaging", "vendor", "*", "*", "cache", "*")

    sh %Q{rm -rf "%s"}                       % tmp_package_dir
    sh %Q{mkdir -p "%s"}                     % tmp_package_dir
    sh %Q{cp Gemfile Gemfile.lock "%s"}      % tmp_package_dir

    sh %Q{ln -sf "%s" "%s"} % [File.expand_path("lib"), tmp_package_dir]

    Bundler.with_clean_env do
      sh %Q{cd "%s" && env BUNDLE_IGNORE_CONFIG=1 bundle install --path ../vendor --without development} % tmp_package_dir
    end

    sh %Q{rm -rf "%s"} % tmp_package_dir
    sh %Q{rm -f "%s"}  % cache_dir
  end

  desc "Build telegraf binaries and move them into this repo"
  task :build_telegraf do
    telegraf_path     = "#{ENV['GOPATH']}/src/github.com/influxdata/telegraf"
    current_directory = File.dirname(__FILE__)
    FileUtils.cd(telegraf_path) # required or it complains about building outside your GOPATH

    # Build all binaries
    version = `git describe --always --tags`.strip
    current_branch = `git rev-parse --abbrev-ref HEAD`.strip
    puts "======================================"
    puts "Now building Telegraf version #{version} from branch #{current_branch}"
    puts "======================================"
    `#{telegraf_path}/scripts/build.py --package --version="#{version}" --platform=linux --arch=all`

    if RUBY_PLATFORM.include?('darwin')
      `env GOOS=darwin GOARCH=amd64 make prepare build`
      `cp #{ENV['GOPATH']}/bin/telegraf #{current_directory}/lib/telegraf/darwin/`
    end

    # Copy them into place
    `cp #{telegraf_path}/build/linux/amd64/telegraf #{current_directory}/lib/telegraf/amd64/`
    `cp #{telegraf_path}/build/linux/i386/telegraf #{current_directory}/lib/telegraf/i386/`
  end

end


def create_packages(directory, platform, architecture, package_formats)
  Array(package_formats).map { |pkg| create_package(directory, pkg, platform, architecture) }
end

def create_package(source, pkg, platform, architecture)
  supported_by_fpm  = %w{deb rpm osxpkg}
  if supported_by_fpm.include?(pkg)
    output_name = [[PACKAGE_OUTPUT_NAME, architecture].join("_"), pkg == "osxpkg" ? "pkg" : pkg].join(".")
    extra_args  = EXTRA_ARGS[pkg] || ""
    # big help: --debug --debug-workspace
    sh %Q{fpm -s tar -t "%s" -f -n "%s" -v "%s" -a "%s" --license "%s" --vendor "%s" --maintainer "%s" --url "%s" --description "%s" --category "%s" --config-files "%s" -C "%s" -p "%s" %s "%s"} % [pkg, PACKAGE_NAME, VERSION, architecture, LICENSE, VENDOR, MAINTAINER, HOMEPAGE, DESCRIPTION, PACKAGE_CATEGORY, CONFIG_DEST, File.basename(source, ".tar.gz"), output_name, extra_args, source]
    output_name
  else
    raise StandardError.new("Format %s is not supported" % pkg)
  end
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
  bundle_dir          = File.join(dest_vendor_dir, ".bundle")


  sh %Q{rm -rf "%s"}   % package_dir
  sh %Q{mkdir "%s"}    % package_dir
  sh %Q{mkdir -p "%s"} % prefixed_dir
  sh %Q{mkdir -p "%s"} % config_dest_dir
  sh %Q{mkdir -p "%s"} % app_dir

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

  bin_files = all_files.select { |path| path.index("bin") == 0 }.map { |path| File.basename(path) }

  all_files.each do |file|
    destination_dir = File.join(app_dir, File.dirname(file))
    FileUtils.mkdir_p(destination_dir)

    sh %Q{cp "%s" "%s"} % [file, destination_dir]
  end

  Dir[File.join(CONFIG_DIR, "*")].each do |file|
    sh %Q{cp "%s" "%s"} % [file, config_dest_dir]
  end

  sh %Q{mkdir "%s"}            % ruby_dir
  sh %Q{tar -xzf "%s" -C "%s"} % [traveling_ruby_file, ruby_dir]

  bin_files.each do |file|
    destination = File.join(prefixed_dir, file + extension.to_s)

    bin_path = "bin" + separator + file
    File.open(destination, "w") { |f| f.write(wrapper_script % bin_path) }

    sh %Q{chmod +x "%s"} % destination
  end

  sh %Q{cp -pR "%s" "%s"}             % [vendor_dir, lib_dir]
  sh %Q{cp Gemfile Gemfile.lock "%s"} % dest_vendor_dir

  sh %Q{ln -sf "../app/%s" "%s"} % ["lib", File.join(dest_vendor_dir, "lib")]

  FileUtils.mkdir_p(bundle_dir)
  File.open(File.join(bundle_dir, "config"), "w") { |f| f.write(BUNDLE_CONFIG) }

  post_build_dir      = File.join(target)
  post_build_makefile = File.join(post_build_dir, "Makefile")
  if File.exists?(post_build_makefile)
    sh %Q{cd "%s" && make clean || /usr/bin/true} % post_build_dir
    sh %Q{cd "%s" && make install prefix="%s"} % [post_build_dir, File.expand_path(package_dir)]
  end
  package_dir
end

def create_compressed_package(package_dir, format = 'tar.gz')
  format ||= 'tar.gz'
  case format
  when 'tar.gz'
    gzip_file   = "%s.tar.gz" % package_dir

    sh %Q{tar -czf "%s" "%s"} % [gzip_file, package_dir]

    gzip_file
  when 'zip'
    zip_file    = "%s.zip" % package_dir

    sh %Q{zip -r "%s" "%s"} % [zip_file, package_dir]

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

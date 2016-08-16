supported_platforms = %w{debian rhel fedora arch gentoo slackware suse}
version   = node[:instrumental][:version]
arch      = case node["kernel"]["machine"]
            when "i386"
              "x86"
            else
              node["kernel"]["machine"]
            end
pkg_arch  = case node["kernel"]["machine"]
            when "x86_64"
              "amd64"
            else
              node["kernel"]["machine"]
            end
file_name = case node["platform_family"]
            when "osx"
              "instrumentald_%s_osx.tar.gz" % version
            when "debian"
              "instrumentald_%s_%s.deb" % [version, pkg_arch]
            when "rhel", "fedora"
              "instrumentald_%s_%s.rpm" % [version, pkg_arch]
            when "windows"
              "instrumentald_%s_win32.exe" % version
            else
              "instrumentald_%s_linux-%s.tar.gz" % [version, arch]
            end

dest_dir            = node[:instrumental][:destination_dir]
local_path          = ::File.join(node[:instrumental][:local_path] || dest_dir, file_name)
conf_file           = node[:instrumental][:config_file]
remote_name         = "%s/%s/%s" % [node[:instrumental][:repo], version, file_name]
package_destination = ::File.join(dest_dir, file_name)

case node["platform_family"]
when "debian", "rhel", "fedora"

  template conf_file do
    source "instrumentald.toml.erb"
    mode   "0440"
    owner  "nobody"
    variables(
      :api_key => node[:instrumental][:api_key]
    )
  end

  if node[:instrumental][:use_local]
    package "instrumentald" do
      action :install
      source local_path
      provider node["platform_family"] == "debian" ? Chef::Provider::Package::Dpkg : Chef::Provider::Package::Yum
    end
  else
    packagecloud_repo "expectedbehavior/instrumental" do
      case node["platform_family"]
      when "debian"
        type "deb"
      when "rhel", "fedora"
        type "rpm"
      end
    end

    package "instrumentald" do
      action :upgrade
      version node[:instrumental]["version"]
    end
  end

  template conf_file do
    source "instrumentald.toml.erb"
    mode   "0440"
    owner  "nobody"
    variables(
      :api_key => node[:instrumental][:api_key]
    )
  end

  template node[:instrumental][:dest_init_file] do
    source "instrumentald.erb"
    mode "0755"
    owner "nobody"
    variables(
      :dest_dir       => dest_dir,
      :config_file    => conf_file,
      :enable_scripts => !!node[:instrumental][:enable_scripts],
      :script_dir     => node[:instrumental][:script_dir],
      :log_file       => node[:instrumental][:log_file],
      :pid_file       => node[:instrumental][:pid_file],
      :user           => node[:instrumental][:user]
    )
  end

  service "instrumentald" do
    action :restart
  end

when "arch", "gentoo", "slackware", "suse", "osx"

  directory dest_dir do
    owner "nobody"
    action :create
    recursive true
  end


  if node[:instrumental][:use_local]
    execute "copy_instrumentald_package" do
      command "cp %s %s" % [local_path, package_destination]
      cwd dest_dir
      user "nobody"
    end
  else
    remote_file package_destination do
      source remote_name
      user "nobody"
    end
  end

  execute "untar_instrumentald_package" do
    command "tar --strip-components=3 -zxvf %s" % file_name
    user "nobody"
    cwd dest_dir
    only_if { ::File.exists?(local_path) }
  end

  template node[:instrumental][:dest_init_file] do
    source "instrumentald.erb"
    mode "0755"
    owner "nobody"
    variables(
      :dest_dir       => dest_dir,
      :config_file    => conf_file,
      :enable_scripts => !!node[:instrumental][:enable_scripts],
      :script_dir     => node[:instrumental][:script_dir],
      :log_file       => node[:instrumental][:log_file],
      :pid_file       => node[:instrumental][:pid_file],
      :user           => node[:instrumental][:user]
    )
  end

  template conf_file do
    source "instrumentald.toml.erb"
    mode   "0440"
    owner  "nobody"
    variables(
      :api_key => node[:instrumental][:api_key]
    )
  end

  service "instrumentald" do
    action [:enable, :start]
    status_command "pgrep instrumentald"
    supports :restart => true, :reload => true, :status => false
  end
when "windows"

  directory dest_dir do
    action :create
    recursive true
  end

  if node[:instrumental][:enable_scripts]
    directory node[:instrumental][:script_dir] do
      action :create
      recursive true
    end
  end

  extra_args = if node[:instrumental][:enable_scripts]
                 '/SD "%s" /E' % node[:instrumental][:script_dir]
               else
                 ""
               end

  if node[:instrumental][:use_local]
    execute "install-tools" do
      command 'call "%s" %s /S /D=%s' % [local_path, extra_args, dest_dir]
    end
  else
    remote_file package_destination do
      source remote_name
      action :create
    end
    execute "install-tools" do
      command 'call "%s" %s /S /D=%s' % [package_destination, extra_args, dest_dir]
    end
  end

  template conf_file do
    source "instrumentald.toml.erb"
    variables(
      :api_key => node[:instrumental][:api_key]
    )
  end

  service "Instrument Server" do
    action [:enable, :start]
  end
else
  Chef::Log.warn("The platform %s is not supported, instrumentald will not be installed" % node["platform_family"])
end

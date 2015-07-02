supported_platforms = %w{debian rhel fedora arch gentoo slackware suse}
version   = node["instrumental"]["version"]
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
              "instrumental-tools_%s_osx.tar.gz" % version
            when "debian"
              "instrumental-tools_%s_%s.deb" % [version, pkg_arch]
            when "rhel", "fedora"
              "instrumental-tools_%s_%s.rpm" % [version, pkg_arch]
            when "windows"
              "instrumental-tools_%s_win32.exe" % version
            else
              "instrumental-tools_%s_linux-%s.tar.gz" % [version, arch]
            end
local_path = ::File.join(node[:instrumental][:local_path], file_name)
dest_dir   = node[:instrumental][:destination_dir]
conf_file  = node[:instrumental][:config_file]

case node["platform_family"]
when "debian", "rhel", "fedora"
  if node[:instrumental][:use_local]
    package "instrumental-tools" do
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

    package "instrumental-tools" do
      action :upgrade
      version node["instrumental"]["version"]
    end
  end

  template conf_file do
    source "instrumental.yml.erb"
    mode   "0440"
    owner  "nobody"
    variables(
      :api_key => node[:instrumental][:api_key]
    )
  end

  template node["instrumental"]["dest_init_file"] do
    source "instrument_server.erb"
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

  service "instrument_server" do
    action :restart
  end

when "arch", "gentoo", "slackware", "suse", "osx"

  local_path = "%s/%s" % [dest_dir, file_name]

  directory dest_dir do
    owner "nobody"
    action :create
    recursive true
  end

  if node[:instrumental][:use_local]
    execute "copy_instrumental_tools_package" do
      command "cp %s %s" % [local_path, ::File.basename(local_path)]
      cwd dest_dir
      user "nobody"
    end
  else
    remote_name = "%s/%s/%s" % [node["instrumental"]["repo"], version, file_name]
    if ::File.exists?(node["instrumental"]["curl_path"])
      execute "curl_download_instrumental_tools_package" do
        command "%s -O %s" % [node["instrumental"]["curl_path"], remote_name]
        cwd dest_dir
        not_if { ::File.exists?(local_path) }
        user "nobody"
      end
    elsif ::File.exists?(node["instrumental"]["wget_path"])
      execute "wget_download_instrumental_tools_package" do
        command "%s %s" % [node["instrumental"]["wget_path"], remote_name]
        cwd dest_dir
        not_if { ::File.exists?(local_path) }
        user "nobody"
      end
    else
      Chef::Log.fatal("Could not find curl or wget, unable to download package")
      raise
    end
  end

  execute "untar_instrumental_tools_package" do
    command "tar --strip-components=3 -zxvf %s" % file_name
    user "nobody"
    cwd dest_dir
    only_if { ::File.exists?(local_path) }
  end

  template node["instrumental"]["dest_init_file"] do
    source "instrument_server.erb"
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
    source "instrumental.yml.erb"
    mode   "0440"
    owner  "nobody"
    variables(
      :api_key => node[:instrumental][:api_key]
    )
  end

  service "instrument_server" do
    action [:enable, :start]
    status_command "pgrep instrument_server"
    supports :restart => true, :reload => true, :status => false
  end
when "windows"
  if node[:instrumental][:use_local]
    execute "install-tools" do
      command "call %s /S /D=%s" % [local_path, dest_dir]
    end
  end

  template conf_file do
    source "instrumental.yml.erb"
    variables(
      :api_key => node[:instrumental][:api_key]
    )
  end

  service "instrument_server" do
    action [:enable, :start]
  end
else
  Chef::Log.warn("The platform %s is not supported, instrumental_tools will not be installed" % node["platform_family"])
end

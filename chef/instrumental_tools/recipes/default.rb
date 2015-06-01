supported_platforms = %w{debian rhel fedora arch gentoo slackware suse}

case node["platform_family"]
when "debian", "rhel", "fedora"
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

  template "/etc/instrumental.yml" do
    source "instrumental.yml.erb"
    mode   "0440"
    owner  "nobody"
    variables(
      :api_key => node[:instrumental][:api_key]
    )
  end
when "arch", "gentoo", "slackware", "suse", "osx"
  version   = node["instrumental"]["version"]
  file_name = if node["platform_family"] == "osx"
                "instrumental-tools_%s_osx.tar.gz" % version
              else
                arch = case node["kernel"]["machine"]
                       when "i386"
                         "x86"
                       else
                         node["kernel"]["machine"]
                       end
                "instrumental-tools_%s_linux-%s.tar.gz" % [version, arch]
              end
  local_path = "/opt/instrumental-tools/%s" % file_name

  directory "/opt/instrumental-tools" do
    owner "nobody"
    action :create
    recursive true
  end

  remote_name = "%s/%s/%s" % [node["instrumental"]["repo"], version, file_name]
  if ::File.exists?(node["instrumental"]["curl_path"])
    execute "curl_download_instrumental_tools_package" do
      command "%s -O %s" % [node["instrumental"]["curl_path"], remote_name]
      cwd "/opt/instrumental-tools"
      not_if { ::File.exists?(local_path) }
      user "nobody"
    end
  elsif ::File.exists?(node["instrumental"]["wget_path"])
    execute "wget_download_instrumental_tools_package" do
      command "%s %s" % [node["instrumental"]["wget_path"], remote_name]
      cwd "/opt/instrumental-tools"
      not_if { ::File.exists?(local_path) }
      user "nobody"
    end
  else
    Chef::Log.fatal("Could not find curl or wget, unable to download package")
    raise
  end

  execute "untar_instrumental_tools_package" do
    command "tar --strip-components=3 -zxvf %s" % file_name
    user "nobody"
    cwd "/opt/instrumental-tools"
    only_if { ::File.exists?(local_path) }
  end

  execute "copy_service_into_place" do
    distributed_file = node["instrumental"]["dist_init_file"]
    destination_file = node["instrumental"]["dest_init_file"]
    command <<-EOSCRIPT % [distributed_file, destination_file, destination_file]
cp %s %s
chmod +x %s
    EOSCRIPT
    not_if { ::File.exists?(node["instrumental"]["dest_init_file"]) }
  end

  template "/etc/instrumental.yml" do
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

else
  Chef::Log.warn("The platform %s is not supported, instrumental_tools will not be installed" % node["platform_family"])
end

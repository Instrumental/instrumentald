default[:instrumental]                   = {}
default[:instrumental][:api_key]         = nil

default[:instrumental][:version]         = "1.1.1"
default[:instrumental][:repo]            = "https://s3.amazonaws.com/instrumental-tools"

default[:instrumental][:curl_path]       = "/usr/bin/curl"
default[:instrumental][:wget_path]       = "/usr/bin/wget"

default[:instrumental][:dest_init_file]  = "/etc/init.d/instrument_server"

default[:instrumental][:enable_scripts]  = false


if node[:platform_family] == "windows"
  default[:instrumental][:destination_dir] = "C:\\Program Files (x86)\\Instrumental Tools"
  default[:instrumental][:config_file]     = "C:\\Program Files (x86)\\Instrumental Tools\\etc\\instrumental.yml"
  default[:instrumental][:script_dir]      = "C:\\Program Files (x86)\\Instrumental Tools\\scripts"
else
  default[:instrumental][:destination_dir] = "/opt/instrumental-tools/"
  default[:instrumental][:config_file]     = "/etc/instrumental.yml"
  default[:instrumental][:script_dir]      = "/opt/instrumental-tools/.scripts"
  default[:instrumental][:pid_file]        = "/opt/instrumental-tools/instrument_server.pid"
  default[:instrumental][:log_file]        = "/opt/instrumental-tools/instrument_server.log"
  default[:instrumental][:user]            = "nobody"
end

default[:instrumental][:use_local]       = false
default[:instrumental][:local_path]      = nil

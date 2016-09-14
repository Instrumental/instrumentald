default[:instrumental]                   = {}
default[:instrumental][:project_token]   = "YOUR_PROJECT_TOKEN"

default[:instrumental][:version]         = "0.0.5"
default[:instrumental][:repo]            = "https://s3.amazonaws.com/instrumentald"

default[:instrumental][:curl_path]       = "/usr/bin/curl"
default[:instrumental][:wget_path]       = "/usr/bin/wget"

default[:instrumental][:dest_init_file]  = "/etc/init.d/instrumentald"

default[:instrumental][:enable_scripts]  = false


if node[:platform_family] == "windows"
  default[:instrumental][:destination_dir] = "C:\\Program Files (x86)\\Instrumentald"
  default[:instrumental][:config_file]     = "C:\\Program Files (x86)\\Instrumentald\\etc\\instrumentald.toml"
  default[:instrumental][:script_dir]      = "C:\\Program Files (x86)\\Instrumentald\\scripts"
else
  default[:instrumental][:destination_dir] = "/opt/instrumentald/"
  default[:instrumental][:config_file]     = "/etc/instrumentald.toml"
  default[:instrumental][:script_dir]      = "/opt/instrumentald/.scripts"
  default[:instrumental][:pid_file]        = "/opt/instrumentald/instrumentald.pid"
  default[:instrumental][:log_file]        = "/opt/instrumentald/instrumentald.log"
  default[:instrumental][:user]            = "nobody"
end

default[:instrumental][:use_local]       = false
default[:instrumental][:local_path]      = nil

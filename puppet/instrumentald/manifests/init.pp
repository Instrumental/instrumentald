class instrumentald(
  $project_token = ''
) {

  include packagecloud

  case $operatingsystem {
    'RedHat', 'CentOS': {
      $package_type = 'rpm'
      $provider = 'rpm'
    }
    'Debian', 'Ubuntu': {
      $package_type = 'deb'
      $provider = 'dpkg'
    }
  }

  packagecloud::repo { "expectedbehavior/instrumental":
    type => $package_type,
  }

  if str2bool("$instrumentald_use_local") {
    package { "instrumentald":
      ensure  => latest,
      provider => $provider,
      source => "/tools-root/instrumentald_${instrumentald_version}_amd64.${package_type}",
      require => Packagecloud::Repo["expectedbehavior/instrumental"]
    }
  } else {
    package { "instrumentald":
      ensure  => latest,
      require => Packagecloud::Repo["expectedbehavior/instrumental"]
    }
  }

  file { "/tmp/instrumentald_scripts/":
    ensure => "directory",
    owner   => "nobody",
    mode    => "0700",
    before => Package["instrumentald"],
    notify  => Service['instrumentald']
  }

  file { "/tmp/instrumentald_scripts/test_script.bash":
    owner   => "nobody",
    mode    => "0700",
    before => Package["instrumentald"],
    content => template("instrumentald/test_script.bash.erb"),
    notify  => Service['instrumentald']
  }

  file { "/tmp/instrumentald_scripts/test_script_no_extension":
    owner   => "nobody",
    mode    => "0700",
    before  => Package["instrumentald"],
    content => template("instrumentald/test_script.bash.erb"),
    notify  => Service["instrumentald"]
  }

  file { "instrumental-config":
    path    => "/etc/instrumentald.toml",
    owner   => "nobody",
    mode    => "0440",
    require => Package["instrumentald"],
    content => template("instrumentald/instrumentald.toml.erb"),
    notify  => Service['instrumentald']
  }

  service { 'instrumentald':
    ensure  => 'running',
    enable  => true,
    require => File['instrumental-config'],
  }
}

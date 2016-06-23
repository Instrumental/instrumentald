class instrumentald(
  $api_key = ''
) {

  include packagecloud

  case $operatingsystem {
    'RedHat', 'CentOS': { $package_type = 'rpm' }
    'Debian', 'Ubuntu': { $package_type = 'deb' }
  }

  packagecloud::repo { "expectedbehavior/instrumental":
    type => $package_type,
  }

  package { "instrumental-tools":
    ensure  => latest,
    require => Packagecloud::Repo["expectedbehavior/instrumental"]
  }

  file { "instrumental-config":
    path    => "/etc/instrumental.yml",
    owner   => "nobody",
    mode    => "0440",
    require => Package["instrumental-tools"],
    content => template("instrumentald/instrumental.yml.erb")
  }

}

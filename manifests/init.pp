class tunneldigger(
  $install_dir='/srv/tunneldigger/tunneldigger',
  $revision='master',
  $virtualenv="/srv/tunneldigger/env_tunneldigger",
  $address,
  $port='53,123,8942',
  $interface,
  $max_tunnels='1024',
  $port_base='20000',
  $tunnel_id_base='100',
  $namespace='default',
  $connection_rate_limit='10',
  $pmtu='0',
  $verbosity='DEBUG',
  $log_ip_addresses='false',
  $templates_dir='tunneldigger',
  $functions='bridge_functions.sh',
  $session_up='',
  $session_pre_down='',
  $session_down='',
  $session_mtu_changed='',
  $bridge_address='10.254.0.2/16',
  $upstart='0'
) {

  package { [
    'iproute',
    'bridge-utils',
    'libnetfilter-conntrack-dev',
    'libnfnetlink-dev',
    'libffi-dev',
    'libevent-dev',
    'ebtables'
  ]:
    ensure => present,
  }

  vcsrepo { $install_dir:
    ensure   => present,
    provider => git,
    source   => 'https://github.com/wlanslovenija/tunneldigger.git',
    revision => $revision,
    require  => [
      Package['git']
    ]
  }

  python::virtualenv { $virtualenv:
    ensure       => present,
    notify       => Exec['setup']
  }

  exec { 'setup':
    command => "${virtualenv}/bin/python setup.py install",
    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    cwd => "${install_dir}/broker",
  }


  file { "${install_dir}/broker/l2tp_broker.cfg":
    ensure    => file,
    content   => template('tunneldigger/l2tp_broker.cfg.erb'),
    require   => Exec['setup'],
  }

  $scripts = "${install_dir}/broker/scripts"

  if $functions {
    file { "${scripts}/${functions}":
      ensure    => file,
      content   => template("${templates_dir}/${functions}.erb"),
      require   => Exec['setup'],
    }
  }

  if $session_up {
    file { "${scripts}/${session_up}":
      ensure    => file,
      content   => template("${templates_dir}/${session_up}.erb"),
      require   => Exec['setup'],
    }
  }

  if $session_pre_down {
    file { "${scripts}/${session_pre_down}":
      ensure    => file,
      content   => template("${templates_dir}/${session_pre_down}.erb"),
      require   => Exec['setup'],
    }
  }

  if $session_down {
    file { "${scripts}/${session_down}":
      ensure    => file,
      content   => template("${templates_dir}/${session_down}.erb"),
      require   => Exec['setup'],
    }
  }

  if $session_mtu_changed {
    file { "${scripts}/${session_mtu_changed}":
      ensure    => file,
      content   => template("${templates_dir}/${session_mtu_changed}.erb"),
      require   => Exec['setup'],
    }
  }

  file { "${install_dir}/broker/scripts/tunneldigger-broker":
    ensure    => file,
    content   => template('tunneldigger/tunneldigger-broker.erb'),
    require   => Exec['setup'],
  }

  if $upstart == '1' {
    file { '/etc/init/tunneldigger.conf':
      ensure    => file,
      content   => template('tunneldigger/tunneldigger.upstart.erb'),
      require   => Exec['setup'],
      notify    => Service['tunneldigger'],
    }
  }

  service { "tunneldigger":
    ensure      => 'running',
    enable      => 'true',
  }

}

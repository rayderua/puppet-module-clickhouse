class clickhouse::install inherits clickhouse {

  require apt
  require clickhouse::repo

  Class['clickhouse::repo']
  -> Class['clickhouse::install']

  Package {
    ensure  => $clickhouse::version,
    require => [
      Apt::Source['clickhouse'],
      Apt::Pin['clickhouse'],
    ]
  }

  File {
    owner => 'clickhouse',
    group => 'clickhouse',
  }

  if ( $clickhouse::install_client == true or $clickhouse::install_server == true) {
    package {['clickhouse-common-static','clickhouse-client']: }
  }

  if ( $clickhouse::install_server == true ) {

    package { 'clickhouse-server': }

    file {'/etc/systemd/system/clickhouse-server@.service':
      owner   => root,
      group   => root,
      source  => "puppet:///modules/${module_name}/clickhouse-server.service",
      notify  => Exec['clickhouse-systemd-reload']
    }

    exec { 'clickhouse-systemd-reload':
      path        => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
      command     => 'systemctl daemon-reload > /dev/null',
      refreshonly => true,
    }
  }
}
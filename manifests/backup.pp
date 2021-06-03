class clickhouse::backup (
  Boolean $install    = false,
  String  $version    = '0.6.0',
  String  $source     = "https://github.com/AlexAkulov/clickhouse-backup/releases/download/v${version}/clickhouse-backup_${version}_amd64.deb",
) inherits clickhouse {

  if ( $install == true ) {
    archive { "/tmp/clickhouse-backup_${version}_amd64.deb":
      ensure => present,
      source => "${source}",
      user   => 'root',
      group  => 'root',
    }

    package { 'clickhouse-backup':
      provider => 'dpkg',
      ensure   => 'present',
      source   => "/tmp/clickhouse-backup_${version}_amd64.deb",
      require  => Archive["/tmp/clickhouse-backup_${version}_amd64.deb"]
    }
  }

  file {'/etc/clickhouse-backup':
    ensure  => present,
  }
}
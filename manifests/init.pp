class clickhouse (
  Boolean $install_backup = $clickhouse::params::install_backup,
  Boolean $install_client = $clickhouse::params::install_client,
  Boolean $install_server = $clickhouse::params::install_server,
  String  $version        = $clickhouse::params::version,
) inherits clickhouse::params {

  if ( $install_client == true ) {
    include 'clickhouse::install'
    include 'clickhouse::client'
    include 'clickhouse::repo'
  }

  if ( $install_server == true ) {
    include 'clickhouse::repo'
    include 'clickhouse::install'
    include 'clickhouse::client'
    include 'clickhouse::server'
  }

  if ( $install_backup == true ) {
    include 'clickhouse::backup'
  }

}

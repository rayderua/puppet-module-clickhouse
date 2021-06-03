define clickhouse::server::config (
  Enum['present', 'absent']         $ensure   = 'present',
  String                            $filename = undef,
  Optional[String]                  $source   = undef,
  Optional[String]                  $content  = undef,
  Optional[String]                  $server   = undef,
  String                            $mode     = '0644',
){

  File {
    owner   => $clickhouse::params::user,
    group   => $clickhouse::params::group,
  }

  if ( $filename == undef ) {
    fail("ERROR: filename required")
  }

  if ( $server == undef ) {
    fail("ERROR: server required")
  }

  if ( $source != undef and $content != undef ) {
    fail("ERROR: use ony one of source/content params!!!")
  }

  case $server {
    'production': {
      $conf_dir = "/etc/clickhouse-server"
    }
    'server': {
      fail("'server' name not allowed")
    }
    'backup': {
      fail("'server' name not allowed")
    }
    default: {
      $conf_dir = "/etc/clickhouse-${server}"
    }
  }

  if ( $source == undef and $content == undef ) {
    file { "${conf_dir}/${filename}":
      ensure  => $ensure,
      require => File[$conf_dir],
      mode    => "$mode",
    }
  } else {

    if ( $source ) {
      file { "${conf_dir}/${filename}":
        ensure  => $ensure,
        source  => $source,
        require => File[$conf_dir],
        mode    => "$mode",
      }
    }

    if ( $content ) {
      file { "${conf_dir}/${filename}":
        ensure  => $ensure,
        content => $content,
        require => File[$conf_dir],
        mode    => "$mode",
      }
    }
  }
}
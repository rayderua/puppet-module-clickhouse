define clickhouse::client::config (
  Enum['present', 'absent']         $ensure   = 'present',
  Optional[String]                  $filename = "conf.d/$name",
  Optional[String]                  $source   = undef,
  Optional[String]                  $content  = undef,
) {

  include clickhouse
  File {
    owner   => $clickhouse::params::user,
    group   => $clickhouse::params::group,
  }

  if ( $source != undef and $content != undef ) {
    fail("ERROR: use ony one of source/content params!!!")
  }

  $conf_dir = "/etc/clickhouse-client"

  if ( $source == undef and $content == undef ) {
    file { "${conf_dir}/${filename}":
      ensure => $ensure,
      require => File[$conf_dir],
    }
  } else {

    if ( $source ) {
      file { "${conf_dir}/${filename}":
        ensure  => $ensure,
        source  => $source,
        require => File[$conf_dir],
      }
    }

    if ( $content ) {
      file { "${conf_dir}/${filename}":
        ensure  => $ensure,
        content => $content,
        require => File[$conf_dir],
      }
    }
  }
}
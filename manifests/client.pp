class clickhouse::client (
  Hash $config = {},
  Hash $configfiles = {},
) {
  include  clickhouse
  File {
    owner   => $clickhouse::params::user,
    group   => $clickhouse::params::group,
    require => Package["clickhouse-client"]
  }

  file {[
    "/etc/clickhouse-client",
    "/etc/clickhouse-client/conf.d"
  ]:
    ensure  => directory,
    mode    => "0755",
    purge   => true,
    recurse => true,
  }


  $_config =deep_merge($clickhouse::params::client_config, $config)
  Clickhouse::Client::Config{ "config.xml":
    filename  => "config.xml",
    content   => clickhouse_hash_to_xml($_config, {"AttrPrefix" => true, 'RootName' => 'config'}),
  }

  $configfiles.each | $configname, $configparam | {
    clickhouse::server::config{ "clickhouse-client/$configname":
      * => $configparam,
    }
  }
}
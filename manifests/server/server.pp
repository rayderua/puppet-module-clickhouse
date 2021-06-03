define clickhouse::server::server (
  Enum['running','stopped'] $ensure       = 'running',
  Boolean                   $enabled      = true,
  Boolean                   $openssl      = false,
  Hash                      $config       = {},
  Hash                      $users        = $clickhouse::params::users,
  Hash                      $configfiles  = {},
  Integer                   $color        = 31,
  Variant[Hash, Undef]      $backup       = undef,
) {

  include clickhouse

  Class['clickhouse::install']
  -> Clickhouse::Server::Server[$title]

  File {
    owner   => $clickhouse::params::user,
    group   => $clickhouse::params::group,
    require => Package["clickhouse-server"]
  }

  Exec { path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin', '/usr/local/sbin'] }

  # dotted config ( e.g. key1.key2.key3 => value )
  # for easy search by keys in the config
  $dotconfig = clickhouse_hasherizer($config)

  case $title {
    'production': {
      $service        = "clickhouse-server"
      $server_name    = 'server'
      $tcp_port       = has_key($config, 'tcp_port') ?     { true => $config['tcp_port'],  default => 9000 }
      $http_port      = has_key($config, 'http_port') ?    { true => $config['http_port'], default => 8123 }
      $data_dir       = '/var/lib/clickhouse'
      $conf_dir       = "/etc/clickhouse-server"
    }
    'server': {
      fail("'server' name not allowed [ used in production instance ]")
    }
    'backup': {
      fail("'backup' name not allowed [ used for clickhosue-backup ]")
    }
    default: {
      $service        = "clickhouse-server@$title"
      $server_name    = $title
      $tcp_port       = has_key($config, 'tcp_port') ?    { true => $config['tcp_port'],  default => undef }
      $http_port      = has_key($config, 'http_port') ?  { true => $config['http_port'],  default => undef }
      $data_dir       = "/var/lib/clickhouse-${title}"
      $conf_dir       = "/etc/clickhouse-${title}"

      # tcp/http ports required
      if ( $tcp_port == undef or $http_port == undef ) {
        fail("ERROR: tcp_port or http_port required")
      }
    }
  }

  ### Overrides
  $display_name   = has_key($config, 'display_name') ? { true => $config['display_name'], default => "$title" }
  $_config_override = {
    'logger' => {
      'log'      => "/var/log/clickhouse-server/clickhouse-${server_name}.log",
      'errorlog' => "/var/log/clickhouse-server/clickhouse-${server_name}.error.log"
    },
    'tcp_port'              => "${tcp_port}",
    'http_port'             => "${http_port}",
    'path'                  => "${data_dir}/",
    'tmp_path'              => "${data_dir}/tmp/",
    'user_files_path'       => "${data_dir}/user_files/",
    'format_schema_path'    => "${data_dir}/format_schemas/",
    'access_control_path'   => "${data_dir}/access",
    'dictionaries_config'   => "${conf_dir}/dictionaries/*.xml",
    'users_config'          => 'users.xml',
    'display_name'          => "${display_name}",
  }

  file {[
    "${conf_dir}",
    "${conf_dir}/config.d",
    "${conf_dir}/users.d",
  ]:
    ensure => directory, mode => "0755", purge => true, recurse => true
  }

  file {"${conf_dir}/dictionaries":
    ensure => directory, mode => "0755", require => File["${conf_dir}"]
  }

  file {"$data_dir": ensure => directory, mode => "0700" }

  file {[
    "${data_dir}/tmp",
    "${data_dir}/user_files",
    "${data_dir}/format_schemas",
    "${data_dir}/preprocessed_configs",
  ]:
    ensure  => directory,
    mode    => "0750",
    require => File[$data_dir]
  }

  file {"${conf_dir}/preprocessed":
    ensure  => link,
    target  => "${data_dir}/preprocessed_configs",
    require => File["${data_dir}/preprocessed_configs"]
  }

  # Generate certificates if not exists
  if ( has_key($dotconfig, 'openSSL.server.certificateFile') ){
    $cert = $dotconfig['openSSL.server.certificateFile']
  } else {

    $cert = "${conf_dir}/server.crt"
    file { "$cert":
      ensure  => present,
      mode    => '0644',
      require => Exec["Clickhouse [$title] generate certificates"],
    }
  }

  if ( has_key($dotconfig, 'openSSL.server.privateKeyFile') ) {
    $key = $dotconfig['openSSL.server.privateKeyFile']
  } else {

    $key  = "${conf_dir}/server.key"
    file { "$key":
      ensure  => present,
      mode    => '0640',
      require => Exec["Clickhouse [$title] generate certificates"],
    }
  }

  if ( has_key($dotconfig, 'openSSL.server.dhParamsFile') ) {
    $dhparam = $dotconfig['openSSL.server.dhParamsFile']
  } else {

    $dhparam = "${conf_dir}/dhparam.pem"
    file { "$dhparam":
      ensure  => present,
      mode    => '0640',
      require => Exec["Clickhouse [$title] generate certificates"],
    }
  }

  $openssl_params = "-new -newkey rsa:4096 -days 3650 -nodes -x509"
  exec { "Clickhouse [$title] generate certificates":
    user    => $clickhouse::params::user,
    command => "openssl req -subj \"/CN=${title}.${hostname}.${domain}\" $params -keyout $key -out $cert",
    onlyif  => ['which openssl', "test ! -f $key", "test ! -f $cert" ],
    refreshonly => true,
  }

  exec { "Clickhouse [$title] generate dhparam [started] (usually 5-6 minutes required)":
    command   => "/usr/bin/date",
    onlyif    => ['which openssl', "test ! -f $dhparam"],
    logoutput => true,
    notify    => Exec["Clickhouse [$title] generate dhparam"],
    refreshonly => true,
  }

  exec { "Clickhouse [$title] generate dhparam":
    user        => $clickhouse::params::user,
    command     => "openssl dhparam -out $dhparam 4096",
    refreshonly => true,
    timeout     => 600,
    require     => Exec["Clickhouse [$title] generate dhparam [started] (usually 5-6 minutes required)"]
  }

  # Result configs
  $_config = deep_merge( deep_merge($clickhouse::params::config, $config), $_config_override)
  $_users = deep_merge($clickhouse::params::users, $users)

  clickhouse::server::config{"clickhouse[${title}]/config.xml":
    server    => $title,
    filename  => 'config.xml',
    content   => clickhouse_hash_to_xml($_config, {"AttrPrefix" => true, 'RootName' => 'yandex'}),
    before    => Service["$service"],
  }

  clickhouse::server::config{"clickhouse[${title}]/users.xml":
    server    => $title,
    filename  => 'users.xml',
    content   => clickhouse_hash_to_xml($_users, {"AttrPrefix" => true, 'RootName' => 'yandex'}),
    mode      => '0640',
    before    => Service["$service"],
  }

  ### Colorise client
  $client_config = {
    'prompt_by_server_display_name' => {
      "$name" => "\x01\e[1;32m\x02[\x01\e[1;${color}m\x02{display_name}\x01\e[1;37m\x02 ${hostname}.${domain}\x01\e[1;32m\x02]\x01\e[0m\x02 \n"
    }
  }

  Clickhouse::Client::Config{ "server_${title}.xml":
    content => clickhouse_hash_to_xml($client_config, {"AttrPrefix" => true, 'RootName' => 'config'}),
  }

  $configfiles.each | $configname, $configparam | {
    clickhouse::server::config{ "clickhouse[${title}]/$configname":
      server    => $title,
      filename  => "config.d/$configname",
      before    => Service["$service"],
      *         => $configparam,
    }
  }

  service {"$service":
    ensure  => $ensure,
    enable  => $enabled,
  }

  ### Backup
  if ( $backup != undef ) {
    validate_hash($backup)
    include clickhouse::backup
    $dotbackup = clickhouse_hasherizer($backup)

    $backup_override = {
      'clickhouse' => {
        'server'    => $name,
        'port'      => $tcp_port,
        'data_path' => $data_dir,
      },
      'gcs' => {
        'path' => has_key($dotbackup,'gcs.path') ? { true => $dotbackup['gcs.path'], default => "${hostname}.${domain}/${name}" }
      }
    }

    $_backup = deep_merge( deep_merge($clickhouse::params::backup_config, $backup), $backup_override)
    file { "/etc/clickhouse-backup/${name}.yaml":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => to_yaml($_backup),
      require => File['/etc/clickhouse-backup']
    }
  }
}
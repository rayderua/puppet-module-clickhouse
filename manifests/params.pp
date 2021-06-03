class clickhouse::params {
  $user           = 'clickhouse'
  $group          = 'clickhouse'
  $data_directory = '/var/lib/clickhouse-instance'
  $conf_directory = '/etc/clickhouse-instance'
  $logs_directory = '/var/log/clickhouse-server'
  $install_server = false
  $install_client = false
  $install_backup = false
  $version        = 'installed'

  $config         = {
    'logger'                               => {
      'level' => 'trace',
      'size'  => '1024M',
      'count' => 10,
    },
    'listen_host'                          => '127.0.0.1',
    'mark_cache_size'                      => 5368709120,
    'openSSL'                              => {
      'server' => {
        'verificationMode'    => 'none',
        'loadDefaultCAFile'   => true,
        'cacheSessions'       => true,
        'disableProtocols'    => 'sslv2,sslv3',
        'preferServerCiphers' => true,
      }
    },
    'max_connections'                      => 4096,
    'keep_alive_timeout'                   => 3,
    'max_concurrent_queries'               => 100,
    'uncompressed_cache_size'              => 8589934592,
    'default_profile'                      => 'default',
    'default_database'                     => 'default',
    'builtin_dictionaries_reload_interval' => 3600,
    'max_session_timeout'                  => 3600,
    'default_session_timeout'              => 60,
    'query_log'                            => {
      'database'                    => 'system',
      'table'                       => 'query_log',
      'partition_by'                => 'toYYYYMM(event_date)',
      'flush_interval_milliseconds' => 7500,
    }
  }

  $client_config = {
    'openSSL'                       => {
      'client' => {
        'loadDefaultCAFile'         => true,
        'cacheSessions'             => true,
        'disableProtocols'          => 'sslv2,sslv3',
        'preferServerCiphers'       => true,
        'invalidCertificateHandler' => {
          'name' => 'RejectCertificateHandler'
        }
      }
    },
    'prompt_by_server_display_name' => {
      'default'    => '{display_name}: ',
    }
  }

  $users = {
    'profiles' => {
      'default' => {
        'max_memory_usage'       => 10000000000,
        'use_uncompressed_cache' => 0,
        'load_balancing'         => 'random',
      },
      'readonly' => {
        'readonly' => 1
      }
    },
    'quotas' => {
      'default' => {
        'interval' => {
          'duration'       => 3600,
          'queries'        => 0,
          'errors'         => 0,
          'result_rows'    => 0,
          'read_rows'      => 0,
          'execution_time' => 0,
        }
      }
    },
    'users' => {
      'default' => {
        'networks' => {
          'ip' => ['127.0.0.1','::1'],
        },
        'profile'  => 'default',
        'quota'    => 'default',
      }
    }
  }

  $backup_config = {
    'general'    => {
      'disable_progress_bar'   => false,
      'backups_to_keep_local'  => 0,
      'backups_to_keep_remote' => 0,
    },
    'clickhouse' => {
      'username'       => 'default',
      'password'       => '',
      'host'           => 'localhost',
      'port'           => 9000,
      'data_path'      => "/var/lib/clickhouse",
      'skip_tables'    => ['system.*'],
      'timeout'        => '5m',
      'freeze_by_part' => false,
    },
    'gcs' => {
      'bucket'             => 'clickhouse-backup',
      'path'               => "${hostname}.${domain}",
      'credentials_file'   => '/etc/gcp-credentials.json',
      'credentials_json'   => '',
      'compression_level'  => 1,
      'compression_format' => 'gzip'
    }
  }
}
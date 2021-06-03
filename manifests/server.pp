class clickhouse::server inherits clickhouse {
  # TODO: validate hash for duplicate ports
  # $servers = clickhouse_validate_clusters( lookup('clickhouse::servers', Hash, 'deep', {}) )
  require clickhouse::install
  $servers = lookup('clickhouse::servers', Hash, 'deep', {})
  $servers.each | $server, $config | {
    clickhouse::server::server{ $server: * => $config}
  }
}
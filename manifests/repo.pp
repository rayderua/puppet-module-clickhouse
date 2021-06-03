class clickhouse::repo inherits clickhouse {

  include apt

  apt::source { 'clickhouse':
    location => 'http://repo.yandex.ru/clickhouse/deb/stable/',
    release  => '',
    repos    => 'main/',
    include  => {
      src => false
    },
    key      => {
      id     => '9EBB357BC2B0876A774500C7C8F1E19FE0C56BD4',
      source => 'https://repo.yandex.ru/clickhouse/CLICKHOUSE-KEY.GPG',
    }
  }

  apt::pin { 'clickhouse':
    packages  => ['clickhouse-server','clickhouse-client','clickhouse-common','clickhouse-tools', 'clickhouse-common-static'],
    origin    => 'repo.yandex.ru',
    priority  => 990,
    require   => Apt::Source['clickhouse']
  }

}
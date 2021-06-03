puppet clickouse module

```
---
### Base class params
clickhouse::client: true            # Install clickhouse-client (default: false)
clickhouse::server: true            # Install clickhouse-server+clickhouse-client (default: false)
clickhouse::version: '20.9.2.20'    # Packages version (default: present) 

### Clikhouse servers
clickhouse::servers:                # Clickhouse instances (
  production:                       # defaul clickhouse setup on /etc/clickhouse-server, /var/lib/clickhouse)
    ensure: running                 # Service ensure
    enabled: false                  # Service ensure
    openssl: true                   # Generate openssl certificates (if definded in openSSL.server section and not exists)    users:          # users.xml
    users:                          
      profiles: {}                  # users.xml profiles section
      quoats:   {}                  # users.xml quotas section
      users:                        # users.xml users section
        rayder:
          password: '76089d6c039b7b82b0d4a6e8c2aa0dffe79355de23ca0b777b8b5a72d6be9d62'
          networks: ['0.0.0.0']
    config:                         # config.xml
      openSSL:
        server:
          certificateFile: '/etc/clickhouse-server/server.crt'
          privateKeyFile: '/etc/clickhouse-server/server.key'
          dhParamsFile: '/etc/clickhouse-server/dhparam.pem'
    configfiles:                    # Other configs will placed in (/etc/clickhouse-server|/etc/clickhouse-<instance>)
      content.xml:                   
        content: |
          # Config content
      source.xml:                   
        source: |
          # Test content from rayder

```
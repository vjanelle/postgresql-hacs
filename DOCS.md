# Home Assistant App: PostgreSQL 18

PostgreSQL 18 app for app-backed databases.

## Configuration

Example app configuration:

```yaml
roles:
  - username: app_login
    password: PASSWORD
    login: true
  - username: app_role
    login: false
databases:
  - name: appdb
    owner: app_login
memberships:
  - group: app_role
    member: app_login
grants:
  - database: appdb
    role: app_role
    privileges:
      - SELECT
      - INSERT
ssl:
  enabled: false
network:
  allowlist:
    - 127.0.0.1/32
    - 192.168.1.0/24
```

When `ssl.enabled` is `true`, also provide `ssl.certfile` and `ssl.keyfile`.

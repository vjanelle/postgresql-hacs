# Home Assistant App: PostgreSQL 18

PostgreSQL 18 database app for Home Assistant.

## About

Use this app to run PostgreSQL 18 for Home Assistant or other local services.

## Example

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

When `ssl.enabled` is `true`, also provide `ssl.certfile` and `ssl.keyfile`. `ssl.certfile` must be readable by the PostgreSQL runtime user. `ssl.keyfile` must be owned by the PostgreSQL runtime user and use mode `400` or `600`.

## Integration Tests

The container-backed integration checks live in `tests/integration/`. They build the add-on image, start a throwaway container, and probe it with `psql` across first boot, restart, SSL, and extension paths.

Run them with:

```bash
bash tests/integration/test_first_boot.sh
bash tests/integration/test_restart_idempotent.sh
bash tests/integration/test_ssl.sh
bash tests/integration/test_extensions.sh
```

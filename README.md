# Home Assistant App: PostgreSQL 18

PostgreSQL 18 database app for Home Assistant.

## About

Use this app to run PostgreSQL 18 for Home Assistant or other local services.

## Operator Runbook

See [docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md](../../docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md) for install, start, and troubleshooting steps.

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

## TLS / SSL

When `ssl.enabled` is `true`, also provide `ssl.certfile` and `ssl.keyfile`.

Current implementation details:
- `render-postgres-config` turns PostgreSQL `ssl = on` only when `ssl.enabled` is true.
- It writes `ssl_cert_file` and `ssl_key_file` into `postgresql.conf` from the add-on options.
- It validates `ssl.certfile` is readable by the PostgreSQL runtime user.
- It validates `ssl.keyfile` is owned by the PostgreSQL runtime user and uses mode `400` or `600`.
- It writes `hostssl ... scram-sha-256` entries for each configured `network.allowlist` CIDR when TLS is enabled; with TLS off it writes `host ... scram-sha-256` instead.
- Local socket access remains `local all all trust`.

Current limitations:
- The add-on currently exposes only server certificate and private key settings; there is no add-on option for CA bundles, CRLs, or client-certificate authentication.
- The integration coverage verifies `sslmode=require`, a negative `verify-ca` case without a trusted CA, and `verify-full` hostname handling (success for `localhost`, failure for `127.0.0.1` with a `localhost` cert). It still does not cover full CA-chain validation workflows.
- The SSL integration test uses a temporary self-signed certificate mounted into `/ssl`, so it verifies add-on wiring and PostgreSQL SSL negotiation rather than production PKI workflows.

## Integration Tests

The container-backed integration checks live in `tests/integration/`. They build the add-on image, start throwaway containers, and probe behavior with `psql` across first boot, restart idempotency, SSL, and bundled extension paths.

Current local status:
- `bash tests/integration/test_first_boot.sh` passes locally.
- `bash tests/integration/test_restart_idempotent.sh` passes locally.
- `bash tests/integration/test_ssl.sh` passes locally.
- `bash tests/integration/test_extensions.sh` passes locally.

Run them with:

```bash
bash tests/integration/test_first_boot.sh
bash tests/integration/test_restart_idempotent.sh
bash tests/integration/test_ssl.sh
bash tests/integration/test_extensions.sh
```

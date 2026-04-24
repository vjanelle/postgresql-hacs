# PostgreSQL 18 Addon Operator Runbook

## What This Add-on Does

This add-on runs PostgreSQL 18 as a Home Assistant addon. It provisions roles, databases, memberships, and grants from the add-on configuration schema. It supports SSL/TLS encryption and configurable network access via pg_hba.conf-style allowlists.

Provisioning is additive-only: v1 creates missing roles, databases, memberships, and grants, and leaves existing access drift in place with warnings. Drift warnings cover undeclared memberships plus undeclared database and schema privileges, including `PUBLIC` ACL entries.

## Install In Home Assistant

1. Add `https://github.com/vjanelle/postgresql-hacs` to Home Assistant as the add-on repository.
2. Open the add-on entry for PostgreSQL 18.
3. Install the add-on.
4. Confirm the configuration schema exposes:
   - `roles` (list of maps with `username`, `password`, `login`)
   - `databases` (list of maps with `name`, `owner`)
   - `memberships` (list of maps with `group`, `member`)
   - `grants` (list of maps with `database`, `role`, `privileges`)
   - `ssl` (map with `enabled`, `certfile`, `keyfile`)
   - `network` (map with `allowlist` — list of CIDR strings)
5. Do not start the add-on until a known-good config has been entered.

## Known-Good Minimal Config

Use this configuration as your starting point:

```yaml
roles:
  - username: app_login
    password: app_password
    login: true
databases:
  - name: appdb
    owner: app_login
memberships: []
grants: []
ssl:
  enabled: false
network:
  allowlist: []
```

When `network.allowlist` is empty, the add-on defaults to allowing only localhost connections (`127.0.0.1/32`, `::1/128`).

## TLS-Enabled Config

Enable SSL/TLS by setting `ssl.enabled` to `true` and providing certificate paths:

```yaml
roles:
  - username: app_login
    password: app_password
    login: true
databases:
  - name: appdb
    owner: app_login
ssl:
  enabled: true
  certfile: /ssl/server.crt
  keyfile: /ssl/server.key
network:
  allowlist:
    - 127.0.0.1/32
```

In Home Assistant, enable the **SSL** storage mount for this add-on in the add-on UI. This maps the Home Assistant `/ssl` directory to `/ssl` inside the container. Place `server.crt` and `server.key` under `/ssl`.

Requirements:
- `ssl.certfile` must be readable by the PostgreSQL runtime user (postgres).
- `ssl.keyfile` must be owned by the postgres user with mode `400` or `600`.

When TLS is enabled, `pg_hba.conf` writes `hostssl` entries for each allowlist CIDR instead of `host`, enforcing encrypted connections. Local socket access remains `local all all trust`.

## Start And Verify

After entering your configuration, start the add-on and verify it starts cleanly. Check the logs for any errors related to role creation or database provisioning.

Drift warnings (if any) indicate existing access that was not declared in your configuration — these are informational and do not prevent startup.

## Connect From A Client

Once running, connect using:

```bash
psql -h <host> -p 5432 -U app_login -d appdb
```

The default password is `app_password`. Change it in production.

When SSL is enabled, use:

```bash
PGSSLMODE=require psql -h <host> -p 5432 -U app_login -d appdb
```

## Troubleshooting

- **Add-on fails to start**: Check logs for provisioning errors. Ensure all required fields are present in your configuration. When `ssl.enabled` is true, both `ssl.certfile` and `ssl.keyfile` must be set.
- **Cannot connect from client**: Verify the network allowlist includes your client's IP/CIDR range. Check that port 5432 is exposed. Default allowlist (when empty) is only localhost (`127.0.0.1/32`, `::1/128`).
- **SSL connection failures**: Ensure `ssl.certfile` and `ssl.keyfile` point to valid files with correct permissions. The cert must be readable by the postgres user; the key must be owned by postgres with mode 400 or 600. Verify the SSL storage mount is enabled in Home Assistant for this add-on.

## Limitations

- **Additive-only provisioning**: v1 creates missing roles, databases, memberships, and grants. It does not remove or modify existing access drift — it emits warnings for undeclared memberships and privileges.
- **No CA bundle support**: Only server certificate and private key settings are supported; no add-on options for CA bundles, CRLs, or client-certificate authentication.
- **Self-signed certs only in testing**: The integration test uses temporary self-signed certificates; production PKI workflows require manual certificate management.
- **Limited certificate validation coverage**: Integration tests cover `sslmode=require`, a failing `verify-ca` path without a trusted CA, and `verify-full` hostname behavior for `localhost` vs `127.0.0.1`. They do not cover full CA-chain validation workflows.

## Backup And Upgrade Notes

- PostgreSQL data lives at `/var/lib/postgresql/data` inside the container, mapped to host `/data` via the add-on storage configuration.
- Back up this directory before any upgrade or major configuration change.
- When upgrading, run the old version's backup first, then install the new version pointing to the same data directory.

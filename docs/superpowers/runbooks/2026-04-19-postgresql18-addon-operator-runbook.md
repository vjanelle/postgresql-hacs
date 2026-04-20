# PostgreSQL 18 Addon Operator Runbook

## What This Add-on Does

This add-on runs PostgreSQL 18 as a Home Assistant addon. It provisions roles, databases, memberships, and grants from the add-on configuration schema. It supports SSL/TLS encryption and configurable network access via pg_hba.conf-style allowlists.

Provisioning is additive-only: v1 creates missing roles, databases, memberships, and grants, and leaves existing access drift in place with warnings. Drift warnings cover undeclared memberships plus undeclared database and schema privileges, including `PUBLIC` ACL entries.

## Install In Home Assistant

1. Add the repository containing this add-on to Home Assistant.
2. Open the add-on entry for PostgreSQL 18.
3. Install the add-on.
4. Confirm the configuration schema exposes:
   - `roles`
   - `databases`
   - `memberships`
   - `grants`
   - `ssl`
   - `network`
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
  certfile: ""
  keyfile: ""
network:
  allowlist:
    - 127.0.0.1/32
```

## TLS-Enabled Config

When `ssl.enabled` is `true`, also provide `ssl.certfile` and `ssl.keyfile`. The cert file must be readable by the PostgreSQL runtime user, and the key file must be owned by the PostgreSQL runtime user with mode `400` or `600`.

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

Mount your SSL certificates into the add-on at `/ssl` via the Home Assistant storage mount configuration.

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

- **Add-on fails to start**: Check logs for provisioning errors. Ensure all required fields are present in your configuration.
- **Cannot connect from client**: Verify the network allowlist includes your client's IP/CIDR range. Check that port 5432 is exposed.
- **SSL connection failures**: When SSL is enabled, ensure `ssl.certfile` and `ssl.keyfile` point to valid files with correct permissions (cert readable by postgres user, key owned by postgres user with mode 400 or 600).

## Limitations

- Additive-only provisioning: v1 creates missing roles, databases, memberships, and grants. It does not remove or modify existing access drift — it emits warnings for undeclared memberships and privileges.
- No CA bundle support: Only server certificate and private key settings are supported; no client-certificate authentication options.
- Self-signed certs only in testing: The integration test uses temporary self-signed certificates; production PKI workflows require manual certificate management.

## Backup And Upgrade Notes

- PostgreSQL data lives at `/data/postgres` inside the container (mapped to `/data` on the host).
- Back up this directory before any upgrade or major configuration change.
- When upgrading, run the old version's backup first, then install the new version pointing to the same data directory.

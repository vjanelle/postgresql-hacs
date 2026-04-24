# Home Assistant App: PostgreSQL 18

PostgreSQL 18 app for app-backed databases.

## Configuration Schema

The add-on configuration supports the following top-level keys:

- **`roles`** (list of maps): Each map has `username` (string), `password` (string), and `login` (boolean).
- **`databases`** (list of maps): Each map has `name` (string) and `owner` (string, must reference an existing role).
- **`memberships`** (list of maps): Each map has `group` (string) and `member` (string). Grants the member role membership in the group.
- **`grants`** (list of maps): Each map has `database` (string), `role` (string), and `privileges` (list of strings, e.g. `SELECT`, `INSERT`).
- **`ssl`** (map): Contains `enabled` (boolean), `certfile` (string path inside container), and `keyfile` (string path inside container).
- **`network`** (map): Contains `allowlist` (list of CIDR strings). When empty, defaults to `127.0.0.1/32` and `::1/128`.

## Example Configuration

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
  allowlist: []
```

## TLS / SSL

When `ssl.enabled` is `true`, also provide `ssl.certfile` and `ssl.keyfile`. These paths are inside the container (for example, `/ssl/server.crt`). Enable the **SSL** storage mount in Home Assistant so certificate material from `/ssl` is available inside the add-on.

Requirements:
- `ssl.certfile` must be readable by the PostgreSQL runtime user (postgres).
- `ssl.keyfile` must be owned by the postgres user with mode `400` or `600`.

When TLS is enabled, remote connections in `pg_hba.conf` use `hostssl` instead of `host`, enforcing encrypted transport. Local socket access remains `local all all trust`.

## Provisioning Behavior

v1 is additive-only: it creates missing roles, databases, memberships, and grants, and leaves existing access drift in place with warnings. Drift warnings cover undeclared memberships plus undeclared database and schema privileges, including `PUBLIC` ACL entries.

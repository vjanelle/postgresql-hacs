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
  host_network: false
```

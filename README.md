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
```

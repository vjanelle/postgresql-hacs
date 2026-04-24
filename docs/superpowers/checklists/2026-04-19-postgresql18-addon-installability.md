# PostgreSQL 18 Addon Installability Checklist

Repository URL: `https://github.com/vjanelle/postgresql-hacs`

- [ ] Repository URL added in Home Assistant
- [ ] Add-on appears in add-on store
- [ ] Add-on metadata renders correctly
- [ ] Install button succeeds
- [ ] Configuration tab shows expected schema fields

## Runtime Reliability

- [x] First boot initializes cluster
- [x] Restart is idempotent
- [x] Invalid config fails early with readable logs
- [x] SSL disabled path works as documented
- [x] SSL enabled path works as documented
- [x] Data survives restart

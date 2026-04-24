# PostgreSQL 18 Addon Provisioning Checklist

- [x] Login roles created
- [x] Non-login roles created
- [x] Memberships applied
- [x] Databases created
- [x] Schemas created
- [x] Grants applied
- [x] Extensions enabled
- [x] Restart remains idempotent
- [x] Additive-only behavior preserved

## Verification

- `timeout 45 bash -x tests/integration/test_first_boot.sh` passed
- `timeout 120 bash tests/integration/test_restart_idempotent.sh` passed
- `timeout 55 bash tests/integration/test_extensions.sh` passed

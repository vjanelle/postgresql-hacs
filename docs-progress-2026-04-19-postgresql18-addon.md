# PostgreSQL 18 Addon Progress

**NOTE: This file tracks development progress only. It is NOT the operator source of truth.**
Operator documentation lives in `docs/superpowers/runbooks/` and `DOCS.md`.

## Source Plan

Primary plan: `docs/superpowers/plans/2026-04-19-postgresql18-addon.md`

## Current Status

Task 1: Completed
- Scaffolded addon metadata and docs.
- Added metadata test and hardened it.
- Result: passed spec and quality review.

Task 2: Completed
- Added PostgreSQL 18 image build with bundled `timescaledb` and `pgvector`.
- Added image build test and hardened path handling.
- Result: passed spec and quality review.

Task 3: Completed
- Added s6 lifecycle, provisioning entrypoint, and startup wiring.
- Fixed init ordering, Supervisor service publish, bounded readiness wait, and schema-owner handling.
- Result: passed spec and quality review.

Task 4: Completed
- Added `render-postgres-config`.
- Implemented TLS and network policy rendering.
- Fixed TLS validation to match runtime and documented key/cert requirements.
- Result: passed spec and quality review.

Task 5: Completed
- Added declarative provisioning scripts and SQL bootstrap files.
- Fixed privilege joining, explicit grant behavior, and identifier quoting in default privileges.
- Result: passed spec and quality review.

Task 6: Completed in working tree, not committed
- Added drift logging and secrets-safe behavior.
- Fixed `PUBLIC` ACL handling, noise filtering, schema-owner comparison, and per-database schema warning dedupe.
- Drift tests pass locally.
- Blocker: commit creation is failing in this environment because GPG signing cannot access writable `~/.gnupg`.

Task 7: Completed in working tree, not committed
- Podman-backed integration harness is in place under `tests/integration/`.
- Local integration coverage now passes for first boot, restart idempotency, SSL, and bundled extensions.
- First-boot coverage confirms role/database bootstrap and login on a fresh data directory.
- Restart coverage confirms provisioning is idempotent across container restarts with the same persisted data directory.
- SSL coverage confirms PostgreSQL negotiates TLS successfully when mounted cert/key files are supplied and `ssl.enabled` is true.
- Extensions coverage confirms bundled `timescaledb` and `vector` are created as expected.

Task 8: Completed in working tree, not committed
- README and progress docs now reflect current integration status.

## TLS Implementation Notes

Main TLS behavior in the current add-on:
- `render-postgres-config` reads `ssl.enabled`, `ssl.certfile`, and `ssl.keyfile` from add-on options.
- TLS stays off unless `ssl.enabled` is true.
- When enabled, the renderer writes `ssl = on`, `ssl_cert_file`, and `ssl_key_file` into `postgresql.conf`.
- The certificate file must be readable by the PostgreSQL runtime user.
- The private key must be owned by the PostgreSQL runtime user and use mode `400` or `600`.
- `pg_hba.conf` switches remote allowlist entries from `host` to `hostssl`, still using `scram-sha-256` authentication.
- Local socket access remains `trust`.

Known TLS limitations still remaining:
- No add-on options yet for CA bundle configuration, CRLs, or client-certificate authentication.
- Test coverage currently proves encrypted transport (`sslmode=require`), includes a negative `verify-ca` check without a trusted CA, and validates `verify-full` hostname behavior (`localhost` success, `127.0.0.1` failure with a `localhost` cert). It does not cover full CA-chain validation.
- The SSL integration path uses a short-lived self-signed certificate mounted into `/ssl` (test bypasses HA storage mapping), so it validates add-on wiring and server-side TLS enablement more than end-to-end PKI management.

## Working Tree Summary

Modified, not fully finalized:
- `README.md`
- `Dockerfile`
- `rootfs/usr/bin/provision-postgres`
- `rootfs/usr/share/postgresql/bootstrap/drift.sql`
- `tests/test_drift_logging.sh`
- `tests/integration/*`
- `docs-progress-2026-04-19-postgresql18-addon.md`

## Known Environment Constraints

- Git commits may fail due to GPG signing in a read-only `~/.gnupg` environment.
- Container runtime work should use Podman here, not Docker.

## Immediate Next Actions

1. Review working-tree changes and decide commit boundaries.
2. Run any broader repo checks desired before commit.
3. Finish release-readiness cleanup when code changes are ready to land.

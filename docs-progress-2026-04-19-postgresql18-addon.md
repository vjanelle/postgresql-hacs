# PostgreSQL 18 Addon Progress

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

Task 7: In progress
- Integration test harness files exist under `tests/integration/`.
- Harness updated toward container runtime abstraction and Podman support.
- First live integration run surfaced a real build issue in `Dockerfile` and that was fixed:
  - Bashio symlink now uses `ln -sf`.
- Latest known blocker from first-boot integration:
  - image build fails because Bashio install step previously recreated `/usr/bin/bashio`; this specific issue has been fixed.
- Current next step:
  - rerun `tests/integration/test_first_boot.sh`
  - continue fixing image/runtime issues until first boot passes
  - then validate restart, SSL, and extensions tests

Task 8: Not started
- Final docs and release-readiness cleanup remain after Task 7.

## Working Tree Summary

Modified, not fully finalized:
- `README.md`
- `Dockerfile`
- `rootfs/usr/bin/provision-postgres`
- `rootfs/usr/share/postgresql/bootstrap/drift.sql`
- `tests/test_drift_logging.sh`
- `tests/integration/*`

## Known Environment Constraints

- Git commits may fail due to GPG signing in a read-only `~/.gnupg` environment.
- Container runtime work should use Podman here, not Docker.

## Immediate Next Actions

1. Re-run Podman-backed `tests/integration/test_first_boot.sh`.
2. Fix remaining image/runtime issues until first boot passes.
3. Run and fix `test_restart_idempotent.sh`, `test_ssl.sh`, and `test_extensions.sh`.
4. Finish Task 8 docs/release readiness.

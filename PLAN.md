# PostgreSQL 18 Addon Production Readiness Gap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the remaining gap from the current PostgreSQL 18 add-on branch to a production-ready v1 that can be installed in Home Assistant, configured from docs, started successfully, and used as a working PostgreSQL instance.

**Architecture:** Keep the existing add-on implementation as the baseline and add only the remaining proof, documentation, and reliability work. Use release gates: installability, runtime reliability, provisioning correctness, operator docs, and a final real Home Assistant smoke test. Treat the real Home Assistant install/start/config flow as the final proof, but only after local gates are green.

**Tech Stack:** Home Assistant add-on conventions, Bash, `bashio`, `s6-overlay`, PostgreSQL 18, `psql`, Podman/Docker-based integration tests, Markdown docs

---

## File Structure

- Modify: `postgresql18-addon/README.md` — keep high-level repository overview aligned with actual behavior and limitations
- Modify: `postgresql18-addon/DOCS.md` — keep end-user add-on config examples aligned with actual schema and runtime behavior
- Modify: `postgresql18-addon/config.yaml` — only if Home Assistant metadata or schema adjustments are needed for actual installability
- Modify: `postgresql18-addon/tests/integration/test_first_boot.sh` — extend first-boot proof only if real HA flow exposes a missing case
- Modify: `postgresql18-addon/tests/integration/test_restart_idempotent.sh` — extend restart proof only if HA/runtime findings require it
- Modify: `postgresql18-addon/tests/integration/test_extensions.sh` — extend extension proof only if HA/runtime findings require it
- Modify: `postgresql18-addon/tests/integration/test_ssl.sh` — extend TLS proof only if HA/runtime findings require it
- Modify: `postgresql18-addon/tests/test_render_postgres_config.sh` — keep config renderer assertions aligned with runtime behavior
- Create: `docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md` — primary operator-facing install/config/verify/troubleshoot doc
- Create: `docs/superpowers/checklists/2026-04-19-postgresql18-addon-smoke-test.md` — step-by-step Home Assistant smoke-test checklist and result log
- Modify: `docs/superpowers/specs/2026-04-19-postgresql18-addon-production-readiness-gap-design.md` — only if execution uncovers a true design gap
- Modify: `docs/superpowers/plans/2026-04-19-postgresql18-addon-production-readiness-gap.md` — update checkboxes and refine steps if facts change during execution

### Task 1: Lock Installability Gate

**Files:**
- Modify: `postgresql18-addon/config.yaml`
- Modify: `postgresql18-addon/README.md`
- Create: `docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md`
- Test: manual Home Assistant repo/add-on discovery flow

- [ ] **Step 1: Write the failing installability checklist**

Create `docs/superpowers/checklists/2026-04-19-postgresql18-addon-installability.md`:

```md
# PostgreSQL 18 Addon Installability Checklist

- [ ] Repository URL added in Home Assistant
- [ ] Add-on appears in add-on store
- [ ] Add-on metadata renders correctly
- [ ] Install button succeeds
- [ ] Configuration tab shows expected schema fields
```

- [ ] **Step 2: Run installability check to verify at least one item is unknown or failing**

Run in Home Assistant using the current branch as-is.
Expected: at least one checklist item is not yet confirmed, which proves this gate still needs validation.

- [ ] **Step 3: Write minimal installability doc section**

Add this section to `docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md`:

```md
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
```

- [ ] **Step 4: Verify Home Assistant installability**

Run the real Home Assistant installability check.
Expected:
- add-on appears
- install succeeds
- configuration UI reflects actual schema

- [ ] **Step 5: Commit**

```bash
git add postgresql18-addon/config.yaml postgresql18-addon/README.md docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md docs/superpowers/checklists/2026-04-19-postgresql18-addon-installability.md
git commit -m "docs: define postgres addon installability gate"
```

### Task 2: Prove Runtime Reliability Gate

**Files:**
- Modify: `postgresql18-addon/tests/integration/test_first_boot.sh`
- Modify: `postgresql18-addon/tests/integration/test_restart_idempotent.sh`
- Modify: `postgresql18-addon/tests/integration/test_ssl.sh`
- Modify: `postgresql18-addon/tests/test_render_postgres_config.sh`
- Modify: `docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md`

- [ ] **Step 1: Write the failing runtime checklist**

Append this section to `docs/superpowers/checklists/2026-04-19-postgresql18-addon-installability.md`:

```md
## Runtime Reliability

- [ ] First boot initializes cluster
- [ ] Restart is idempotent
- [ ] Invalid config fails early with readable logs
- [ ] SSL disabled path works as documented
- [ ] SSL enabled path works as documented
- [ ] Data survives restart
```

- [ ] **Step 2: Run targeted tests to identify any red gate**

Run:

```bash
bash tests/test_render_postgres_config.sh
timeout 45 bash -x tests/integration/test_first_boot.sh
timeout 55 bash tests/integration/test_restart_idempotent.sh
timeout 120 bash tests/integration/test_ssl.sh
```

Expected: all pass, or one fails with a concrete runtime gap to fix before continuing.

- [ ] **Step 3: Write minimal runtime fixes if any test fails**

Use the smallest code change needed in the specific failing file:

- config-rendering failures: `rootfs/usr/bin/render-postgres-config`
- first-boot failures: `rootfs/etc/s6-overlay/s6-rc.d/postgres-pre/run`
- restart failures: `rootfs/etc/s6-overlay/s6-rc.d/postgres-post/run` or provisioning scripts
- TLS failures: `tests/integration/test_ssl.sh`, `rootfs/usr/bin/render-postgres-config`, or related lifecycle scripts

Code rule:

```bash
# Fix only the failing behavior. Do not refactor unrelated startup logic.
```

- [ ] **Step 4: Re-run runtime tests to verify green**

Run:

```bash
bash tests/test_render_postgres_config.sh
timeout 45 bash -x tests/integration/test_first_boot.sh
timeout 55 bash tests/integration/test_restart_idempotent.sh
timeout 120 bash tests/integration/test_ssl.sh
```

Expected: PASS for all commands.

- [ ] **Step 5: Commit**

```bash
git add postgresql18-addon/tests/integration/test_first_boot.sh postgresql18-addon/tests/integration/test_restart_idempotent.sh postgresql18-addon/tests/integration/test_ssl.sh postgresql18-addon/tests/test_render_postgres_config.sh postgresql18-addon/rootfs docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md docs/superpowers/checklists/2026-04-19-postgresql18-addon-installability.md
git commit -m "fix: harden postgres addon runtime gate"
```

### Task 3: Prove Provisioning Correctness Gate

**Files:**
- Modify: `postgresql18-addon/tests/integration/test_first_boot.sh`
- Modify: `postgresql18-addon/tests/integration/test_extensions.sh`
- Modify: `postgresql18-addon/rootfs/usr/bin/provision-postgres`
- Modify: `postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/roles.sql`
- Modify: `postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/memberships.sql`
- Modify: `postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/databases.sql`
- Modify: `postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/schemas.sql`
- Modify: `postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/grants.sql`
- Modify: `docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md`

- [ ] **Step 1: Write the failing provisioning checklist**

Create `docs/superpowers/checklists/2026-04-19-postgresql18-addon-provisioning.md`:

```md
# PostgreSQL 18 Addon Provisioning Checklist

- [ ] Login roles created
- [ ] Non-login roles created
- [ ] Memberships applied
- [ ] Databases created
- [ ] Schemas created
- [ ] Grants applied
- [ ] Extensions enabled
- [ ] Restart remains idempotent
- [ ] Additive-only behavior preserved
```

- [ ] **Step 2: Run provisioning-focused tests to verify the current red/green state**

Run:

```bash
timeout 45 bash -x tests/integration/test_first_boot.sh
timeout 55 bash tests/integration/test_restart_idempotent.sh
timeout 55 bash tests/integration/test_extensions.sh
```

Expected: PASS for all, or a concrete provisioning gap appears.

- [ ] **Step 3: Add one failing test for any missing real-world provisioning gap**

If the current suite misses a behavior exposed by real usage, add one narrow assertion in the smallest relevant file:

```bash
# Example targets:
# - role/schema visibility in tests/integration/test_first_boot.sh
# - extension enablement in tests/integration/test_extensions.sh
# - additive-only restart behavior in tests/integration/test_restart_idempotent.sh
```

Expected before fix: FAIL for the newly added assertion.

- [ ] **Step 4: Write minimal provisioning implementation**

If Step 3 found a real gap, patch only the responsible provisioning unit:

- `rootfs/usr/bin/provision-postgres`
- `rootfs/usr/share/postgresql/bootstrap/*.sql`

Implementation rule:

```sql
-- Change only the SQL or orchestration needed for the missing behavior.
-- Preserve additive-only semantics.
```

- [ ] **Step 5: Run provisioning tests to verify green**

Run:

```bash
timeout 45 bash -x tests/integration/test_first_boot.sh
timeout 55 bash tests/integration/test_restart_idempotent.sh
timeout 55 bash tests/integration/test_extensions.sh
```

Expected: PASS for all commands.

- [ ] **Step 6: Commit**

```bash
git add postgresql18-addon/tests/integration/test_first_boot.sh postgresql18-addon/tests/integration/test_restart_idempotent.sh postgresql18-addon/tests/integration/test_extensions.sh postgresql18-addon/rootfs/usr/bin/provision-postgres postgresql18-addon/rootfs/usr/share/postgresql/bootstrap docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md docs/superpowers/checklists/2026-04-19-postgresql18-addon-provisioning.md
git commit -m "fix: close postgres addon provisioning gaps"
```

### Task 4: Write Operator Runbook

**Files:**
- Create: `docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md`
- Modify: `postgresql18-addon/README.md`
- Modify: `postgresql18-addon/DOCS.md`
- Modify: `postgresql18-addon/docs-progress-2026-04-19-postgresql18-addon.md`

- [ ] **Step 1: Write the failing docs checklist**

Create `docs/superpowers/checklists/2026-04-19-postgresql18-addon-docs.md`:

```md
# PostgreSQL 18 Addon Docs Checklist

- [ ] Install instructions exist
- [ ] Known-good config exists
- [ ] TLS config example exists
- [ ] Client connection example exists
- [ ] Troubleshooting section exists
- [ ] Limitations/non-goals section exists
```

- [ ] **Step 2: Verify current docs are insufficient**

Read:

```bash
sed -n '1,240p' README.md
sed -n '1,260p' DOCS.md
sed -n '1,260p' docs-progress-2026-04-19-postgresql18-addon.md
```

Expected: at least one checklist item is missing, split across files, or not operator-friendly enough to serve as the single runbook.

- [ ] **Step 3: Write the operator runbook**

Create `docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md` with these sections:

```md
# PostgreSQL 18 Addon Operator Runbook

## What This Add-on Does
## Install In Home Assistant
## Known-Good Minimal Config
## TLS-Enabled Config
## Start And Verify
## Connect From A Client
## Troubleshooting
## Limitations
## Backup And Upgrade Notes
```

Known-good config must include actual schema keys now in use:

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

- [ ] **Step 4: Align README and DOCS with runbook**

Make `README.md` point to the runbook as the primary operator doc. Make `DOCS.md` match current schema keys, TLS semantics, and limitations. Reduce or clearly label `docs-progress-2026-04-19-postgresql18-addon.md` as progress notes, not the operator source of truth.

- [ ] **Step 5: Review docs against actual behavior**

Cross-check docs against:

```bash
sed -n '1,240p' config.yaml
sed -n '1,240p' rootfs/usr/bin/render-postgres-config
sed -n '1,240p' tests/integration/test_ssl.sh
```

Expected: examples and wording match real schema and behavior.

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md docs/superpowers/checklists/2026-04-19-postgresql18-addon-docs.md postgresql18-addon/README.md postgresql18-addon/DOCS.md postgresql18-addon/docs-progress-2026-04-19-postgresql18-addon.md
git commit -m "docs: add postgres addon operator runbook"
```

### Task 5: Execute Real Home Assistant Smoke Test

**Files:**
- Create: `docs/superpowers/checklists/2026-04-19-postgresql18-addon-smoke-test.md`
- Modify: `docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md`
- Modify: `postgresql18-addon/README.md`
- Modify: `postgresql18-addon/DOCS.md`
- Modify: `postgresql18-addon/config.yaml` only if real Home Assistant behavior proves metadata/schema mismatch

- [ ] **Step 1: Write the failing smoke-test checklist**

Create `docs/superpowers/checklists/2026-04-19-postgresql18-addon-smoke-test.md`:

```md
# PostgreSQL 18 Addon Home Assistant Smoke Test

- [ ] Repository added
- [ ] Add-on discovered
- [ ] Add-on installed
- [ ] Known-good config pasted
- [ ] Add-on started
- [ ] Logs show healthy startup
- [ ] PostgreSQL reachable
- [ ] Expected DB/user state present
- [ ] Runbook required no undocumented workaround
```

- [ ] **Step 2: Run the smoke test exactly as documented**

Use only the operator runbook for this flow.
Expected: one of two outcomes:
- PASS with no undocumented steps
- FAIL with a concrete install/runtime/docs gap

- [ ] **Step 3: Fix only the gap exposed by the smoke test**

Use the smallest responsible file:

- metadata/install gap: `config.yaml`, `README.md`, `DOCS.md`
- startup gap: `rootfs/etc/s6-overlay/s6-rc.d/*`
- provisioning gap: `rootfs/usr/bin/provision-postgres`, bootstrap SQL
- docs gap: operator runbook or top-level docs

Rule:

```bash
# Fix fact, then update docs to match fact.
```

- [ ] **Step 4: Re-run the smoke test**

Repeat the exact documented flow.
Expected: PASS for all checklist items.

- [ ] **Step 5: Capture final deployment notes**

Append to `docs/superpowers/checklists/2026-04-19-postgresql18-addon-smoke-test.md`:

```md
## Final Notes

- Home Assistant environment used:
- Repository URL used:
- Known-good config used:
- Verification client/app used:
- Any remaining caveats:
```

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/checklists/2026-04-19-postgresql18-addon-smoke-test.md docs/superpowers/runbooks/2026-04-19-postgresql18-addon-operator-runbook.md postgresql18-addon/README.md postgresql18-addon/DOCS.md postgresql18-addon/config.yaml postgresql18-addon/rootfs
git commit -m "docs: record postgres addon home assistant smoke test"
```

### Task 6: Final Production Readiness Review

**Files:**
- Modify: `docs/superpowers/specs/2026-04-19-postgresql18-addon-production-readiness-gap-design.md`
- Modify: `docs/superpowers/plans/2026-04-19-postgresql18-addon-production-readiness-gap.md`
- Modify: `docs/superpowers/checklists/2026-04-19-postgresql18-addon-installability.md`
- Modify: `docs/superpowers/checklists/2026-04-19-postgresql18-addon-provisioning.md`
- Modify: `docs/superpowers/checklists/2026-04-19-postgresql18-addon-docs.md`
- Modify: `docs/superpowers/checklists/2026-04-19-postgresql18-addon-smoke-test.md`

- [ ] **Step 1: Run final verification commands**

Run:

```bash
bash tests/test_render_postgres_config.sh
timeout 45 bash -x tests/integration/test_first_boot.sh
timeout 55 bash tests/integration/test_restart_idempotent.sh
timeout 55 bash tests/integration/test_extensions.sh
timeout 120 bash tests/integration/test_ssl.sh
```

Expected: PASS for all commands.

- [ ] **Step 2: Verify all readiness checklists are green**

Open and confirm all items checked:

```bash
sed -n '1,220p' docs/superpowers/checklists/2026-04-19-postgresql18-addon-installability.md
sed -n '1,220p' docs/superpowers/checklists/2026-04-19-postgresql18-addon-provisioning.md
sed -n '1,220p' docs/superpowers/checklists/2026-04-19-postgresql18-addon-docs.md
sed -n '1,260p' docs/superpowers/checklists/2026-04-19-postgresql18-addon-smoke-test.md
```

Expected: all gates satisfied.

- [ ] **Step 3: Update design or plan only if execution changed facts**

Allowed update examples:

```md
- actual supported HA environment is narrower than planned
- smoke test exposed a new permanent caveat
- a gate needed an additional explicit acceptance criterion
```

- [ ] **Step 4: Write final release note summary**

Add a short completion section to the smoke-test checklist:

```md
## Production Readiness Summary

- Installability gate:
- Runtime reliability gate:
- Provisioning correctness gate:
- Operator docs gate:
- Deployment proof gate:
```

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-04-19-postgresql18-addon-production-readiness-gap-design.md docs/superpowers/plans/2026-04-19-postgresql18-addon-production-readiness-gap.md docs/superpowers/checklists
git commit -m "docs: finalize postgres addon production readiness review"
```

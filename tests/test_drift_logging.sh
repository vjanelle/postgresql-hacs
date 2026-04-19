#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

grep -q "drift.sql" rootfs/usr/bin/provision-postgres
grep -q "undeclared memberships" rootfs/usr/share/postgresql/bootstrap/drift.sql
grep -q "undeclared database privileges" rootfs/usr/share/postgresql/bootstrap/drift.sql
grep -q "undeclared schema privileges" rootfs/usr/share/postgresql/bootstrap/drift.sql
grep -q "v1 is additive-only" DOCS.md

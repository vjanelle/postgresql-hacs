#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

test -f config.yaml
test -f build.yaml
test -f README.md
test -f DOCS.md
grep -q "^version: 18.0.0$" config.yaml
grep -q "^slug: postgresql18$" config.yaml
grep -q "^name: PostgreSQL 18$" config.yaml
grep -q "^description: PostgreSQL 18 database app for Home Assistant\\.$" config.yaml
grep -q "^arch:$" config.yaml
grep -q "^  - aarch64$" config.yaml
grep -q "^  - amd64$" config.yaml
grep -q "^  - armv7$" config.yaml
grep -q "^  - armhf$" config.yaml
grep -q "^  - i386$" config.yaml
grep -q "^startup: services$" config.yaml
grep -q "^image: ghcr.io/home-assistant/{arch}-addon-postgresql18$" config.yaml
grep -q "^ports:$" config.yaml
grep -q "5432/tcp" config.yaml
grep -q "^map:$" config.yaml
grep -q "^options:$" config.yaml
grep -q "^schema:$" config.yaml
grep -q "^  roles:$" config.yaml
grep -q "^  databases:$" config.yaml
grep -q "^  memberships:$" config.yaml
grep -q "^  grants:$" config.yaml
grep -q "^  ssl:$" config.yaml
grep -q "^  network:$" config.yaml
grep -q "^roles:$" README.md
grep -q "^databases:$" README.md
grep -q "^memberships:$" README.md
grep -q "^grants:$" README.md
grep -q "^ssl:$" README.md
grep -q "^network:$" README.md
grep -q "^roles:$" DOCS.md
grep -q "^databases:$" DOCS.md
grep -q "^memberships:$" DOCS.md
grep -q "^grants:$" DOCS.md
grep -q "^ssl:$" DOCS.md
grep -q "^network:$" DOCS.md
! grep -Eq '^(schemas|admins|extensions):' README.md
! grep -Eq '^(schemas|admins|extensions):' DOCS.md
grep -q "^build_from:$" build.yaml
grep -q "^  aarch64: ghcr.io/home-assistant/aarch64-base-debian:bookworm$" build.yaml
grep -q "^  amd64: ghcr.io/home-assistant/amd64-base-debian:bookworm$" build.yaml
grep -q "^  armv7: ghcr.io/home-assistant/armv7-base-debian:bookworm$" build.yaml
grep -q "^  armhf: ghcr.io/home-assistant/armhf-base-debian:bookworm$" build.yaml
grep -q "^  i386: ghcr.io/home-assistant/i386-base-debian:bookworm$" build.yaml

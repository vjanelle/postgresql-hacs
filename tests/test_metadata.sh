#!/usr/bin/env bash
set -euo pipefail

test -f repository.yaml
test -f config.yaml
test -f build.yaml
test -f README.md
test -f DOCS.md
grep -q "name: PostgreSQL Home Assistant Add-ons" repository.yaml
grep -q "slug: postgresql18" config.yaml
grep -q 'version: "0.1.0"' config.yaml
grep -q "5432/tcp" config.yaml

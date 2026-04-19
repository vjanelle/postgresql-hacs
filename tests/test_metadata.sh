#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

test -f config.yaml
test -f build.yaml
test -f README.md
test -f DOCS.md
grep -q "slug: postgresql18" config.yaml
grep -q "5432/tcp" config.yaml

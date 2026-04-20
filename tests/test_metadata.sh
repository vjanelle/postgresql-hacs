#!/usr/bin/env bash
set -euo pipefail

test -f postgresql18-addon/config.yaml
test -f postgresql18-addon/build.yaml
test -f postgresql18-addon/README.md
test -f postgresql18-addon/DOCS.md
grep -q "slug: postgresql18" postgresql18-addon/config.yaml
grep -q "5432/tcp" postgresql18-addon/config.yaml

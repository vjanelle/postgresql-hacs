#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

grep -q "postgresql-18" Dockerfile
grep -Eq "timescaledb|pgvector|vector" Dockerfile

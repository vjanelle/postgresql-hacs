#!/usr/bin/env bash
set -euo pipefail

grep -q "postgresql-18" postgresql18-addon/Dockerfile
grep -Eq "timescaledb|pgvector|vector" postgresql18-addon/Dockerfile

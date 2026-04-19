#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

source tests/integration/lib.sh

tmpdir="$(mktemp -d)"
container="$(integration::container_name restart)"

cleanup() {
  integration::cleanup_container "${container}"
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

cat >"${tmpdir}/options.json" <<'EOF'
{
  "roles": [
    {
      "username": "app_login",
      "password": "app_password",
      "login": true
    }
  ],
  "databases": [
    {
      "name": "appdb",
      "owner": "app_login"
    }
  ],
  "memberships": [],
  "grants": [],
  "ssl": {
    "enabled": false
  },
  "network": {
    "allowlist": [
      "127.0.0.1/32"
    ]
  }
}
EOF

integration::build_image
integration::start_container "${container}" "${tmpdir}/options.json" "${tmpdir}/data"
integration::wait_for_psql "${container}" appdb app_login app_password disable 127.0.0.1 "SELECT 1"

first_role_count="$(integration::psql "${container}" appdb app_login app_password disable 127.0.0.1 "SELECT count(*) FROM pg_roles WHERE rolname = 'app_login';")"
first_db_count="$(integration::psql "${container}" appdb app_login app_password disable 127.0.0.1 "SELECT count(*) FROM pg_database WHERE datname = 'appdb';")"

integration::cleanup_container "${container}"
integration::start_container "${container}" "${tmpdir}/options.json" "${tmpdir}/data"
integration::wait_for_psql "${container}" appdb app_login app_password disable 127.0.0.1 "SELECT 1"

second_role_count="$(integration::psql "${container}" appdb app_login app_password disable 127.0.0.1 "SELECT count(*) FROM pg_roles WHERE rolname = 'app_login';")"
second_db_count="$(integration::psql "${container}" appdb app_login app_password disable 127.0.0.1 "SELECT count(*) FROM pg_database WHERE datname = 'appdb';")"

test "${first_role_count}" -eq 1
test "${first_db_count}" -eq 1
test "${second_role_count}" -eq 1
test "${second_db_count}" -eq 1

#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

source tests/integration/lib.sh

tmpdir="$(mktemp -d)"
container="$(integration::container_name extensions)"

cleanup() {
  integration::cleanup_container "${container}"
  integration::cleanup_all_test_containers
  integration::cleanup_tmpdir "${tmpdir}"
}
trap cleanup EXIT

integration::cleanup_all_test_containers

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

test "$(integration::psql "${container}" appdb app_login app_password disable 127.0.0.1 "SELECT count(*) FROM pg_extension WHERE extname IN ('timescaledb', 'vector');")" -eq 2

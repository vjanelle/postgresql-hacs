#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

source tests/integration/lib.sh

tmpdir="$(mktemp -d)"
container="$(integration::container_name ssl)"

cleanup() {
  integration::cleanup_container "${container}"
  integration::cleanup_all_test_containers
  integration::cleanup_tmpdir "${tmpdir}"
}
trap cleanup EXIT

integration::cleanup_all_test_containers

write_common_options() {
  local options_file="$1"
  local ssl_enabled="$2"
  local cert_path="$3"
  local key_path="$4"

  cat >"${options_file}" <<EOF
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
    "enabled": ${ssl_enabled},
    "certfile": "${cert_path}",
    "keyfile": "${key_path}"
  },
  "network": {
    "allowlist": [
      "127.0.0.1/32"
    ]
  }
}
EOF
}

write_common_options "${tmpdir}/ssl-off.json" false "" ""
integration::build_image
integration::start_container "${container}" "${tmpdir}/ssl-off.json" "${tmpdir}/data-off"
integration::wait_for_psql "${container}" appdb app_login app_password disable 127.0.0.1 "SELECT 1"

if integration::psql "${container}" appdb app_login app_password require 127.0.0.1 "SELECT 1" >/dev/null 2>&1; then
  exit 1
fi

integration::cleanup_container "${container}"

mkdir -p "${tmpdir}/ssl"
openssl req \
  -x509 \
  -nodes \
  -newkey rsa:2048 \
  -keyout "${tmpdir}/ssl/server.key" \
  -out "${tmpdir}/ssl/server.crt" \
  -days 1 \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost" >/dev/null 2>&1
integration::prepare_ssl_dir "${tmpdir}/ssl"
write_common_options "${tmpdir}/ssl-on.json" true "/ssl/server.crt" "/ssl/server.key"

integration::start_container "${container}" "${tmpdir}/ssl-on.json" "${tmpdir}/data-on" -v "${tmpdir}/ssl:/ssl:ro"
integration::wait_for_psql "${container}" appdb app_login app_password require 127.0.0.1 "SELECT 1"

test "$(integration::psql "${container}" appdb app_login app_password require 127.0.0.1 "SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid();")" = "t"

if integration::psql "${container}" appdb app_login app_password verify-ca 127.0.0.1 "SELECT 1" >/dev/null 2>&1; then
  exit 1
fi

container_bin="$(integration::container_bin)"
test "$("${container_bin}" exec \
  -e PGPASSWORD="app_password" \
  -e PGSSLMODE="verify-full" \
  -e PGSSLROOTCERT="/ssl/server.crt" \
  "${container}" \
  psql \
    --no-psqlrc \
    --quiet \
    --tuples-only \
    --no-align \
    --set=ON_ERROR_STOP=1 \
    --host "localhost" \
    --username "app_login" \
    --dbname "appdb" \
    --command "SELECT 1")" = "1"

if "${container_bin}" exec \
  -e PGPASSWORD="app_password" \
  -e PGSSLMODE="verify-full" \
  -e PGSSLROOTCERT="/ssl/server.crt" \
  "${container}" \
  psql \
    --no-psqlrc \
    --quiet \
    --tuples-only \
    --no-align \
    --set=ON_ERROR_STOP=1 \
    --host "127.0.0.1" \
    --username "app_login" \
    --dbname "appdb" \
    --command "SELECT 1" >/dev/null 2>&1; then
  exit 1
fi

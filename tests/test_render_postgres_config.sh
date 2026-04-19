#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

bashio_lib="${tmpdir}/bashio"
cat >"${bashio_lib}" <<'EOF'
#!/usr/bin/env bash

bashio::log.info() {
  :
}

bashio::exit.nok() {
  printf '%s\n' "$*" >&2
  exit 1
}

bashio::var.true() {
  case "${1,,}" in
    true|1|yes|on)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

bashio::config.exists() {
  case "$1" in
    ssl.certfile|ssl.keyfile|network.allowlist|network.host_network)
      [[ -n "${BASHIO_CONFIG_EXISTS:-1}" ]]
      ;;
    *)
      return 1
      ;;
  esac
}

bashio::config() {
  local key="$1"

  if [[ "${key}" == "ssl.enabled" ]]; then
    printf '%s\n' "${BASHIO_SSL_ENABLED:-false}"
  elif [[ "${key}" == "ssl.certfile" ]]; then
    printf '%s\n' "${BASHIO_SSL_CERTFILE:-}"
  elif [[ "${key}" == "ssl.keyfile" ]]; then
    printf '%s\n' "${BASHIO_SSL_KEYFILE:-}"
  elif [[ "${key}" == "network.host_network" ]]; then
    printf '%s\n' "${BASHIO_HOST_NETWORK:-false}"
  elif [[ "${key}" == "network.allowlist|length" ]]; then
    if [[ -z "${BASHIO_ALLOWLIST:-}" ]]; then
      printf '0\n'
    else
      mapfile -t _bashio_allowlist <<< "${BASHIO_ALLOWLIST}"
      printf '%s\n' "${#_bashio_allowlist[@]}"
    fi
  elif [[ "${key}" == "network.allowlist|keys" ]]; then
    if [[ -n "${BASHIO_ALLOWLIST:-}" ]]; then
      mapfile -t _bashio_allowlist <<< "${BASHIO_ALLOWLIST}"
      local i
      for i in "${!_bashio_allowlist[@]}"; do
        printf '%s\n' "${i}"
      done
    fi
  elif [[ "${key}" =~ ^network\.allowlist\[([0-9]+)\]$ ]]; then
    local index="${BASH_REMATCH[1]}"
    mapfile -t _bashio_allowlist <<< "${BASHIO_ALLOWLIST:-}"
    printf '%s\n' "${_bashio_allowlist[${index}]:-}"
  else
    return 1
  fi
}
EOF
chmod +x "${bashio_lib}"

render() {
  local data_dir="$1"
  shift

  env \
    BASHIO_LIB="${bashio_lib}" \
    POSTGRES_DATA_DIR="${data_dir}" \
    POSTGRES_RUNTIME_DIR="${tmpdir}/run" \
    "$@" \
    bash rootfs/usr/bin/render-postgres-config
}

ssl_off_dir="${tmpdir}/ssl-off"
mkdir -p "${ssl_off_dir}"
render "${ssl_off_dir}" \
  BASHIO_SSL_ENABLED=false \
  BASHIO_HOST_NETWORK=false \
  BASHIO_ALLOWLIST=$'10.0.0.0/24\n192.168.1.0/24'

grep -q "^listen_addresses = " "${ssl_off_dir}/postgresql.conf"
grep -q "^shared_preload_libraries = 'timescaledb'$" "${ssl_off_dir}/postgresql.conf"
grep -q "^ssl = off$" "${ssl_off_dir}/postgresql.conf"
if grep -q "^ssl_cert_file =" "${ssl_off_dir}/postgresql.conf"; then
  exit 1
fi
if grep -q "^ssl_key_file =" "${ssl_off_dir}/postgresql.conf"; then
  exit 1
fi
grep -q "^local all all trust$" "${ssl_off_dir}/pg_hba.conf"
grep -q "^host all all 10.0.0.0/24 scram-sha-256$" "${ssl_off_dir}/pg_hba.conf"
grep -q "^host all all 192.168.1.0/24 scram-sha-256$" "${ssl_off_dir}/pg_hba.conf"
if grep -q "^hostssl " "${ssl_off_dir}/pg_hba.conf"; then
  exit 1
fi

cert_file="${tmpdir}/server.crt"
key_file="${tmpdir}/server.key"
: > "${cert_file}"
: > "${key_file}"
chmod 644 "${cert_file}"
chmod 600 "${key_file}"

ssl_on_dir="${tmpdir}/ssl-on"
mkdir -p "${ssl_on_dir}"
render "${ssl_on_dir}" \
  BASHIO_SSL_ENABLED=true \
  BASHIO_SSL_CERTFILE="${cert_file}" \
  BASHIO_SSL_KEYFILE="${key_file}" \
  BASHIO_HOST_NETWORK=true \
  BASHIO_ALLOWLIST=$'10.0.0.0/24\n192.168.1.0/24'

grep -q "^ssl = on$" "${ssl_on_dir}/postgresql.conf"
grep -q "^ssl_cert_file = '${cert_file}'$" "${ssl_on_dir}/postgresql.conf"
grep -q "^ssl_key_file = '${key_file}'$" "${ssl_on_dir}/postgresql.conf"
grep -q "^hostssl all all 10.0.0.0/24 scram-sha-256$" "${ssl_on_dir}/pg_hba.conf"
grep -q "^hostssl all all 192.168.1.0/24 scram-sha-256$" "${ssl_on_dir}/pg_hba.conf"

bad_cert_dir="${tmpdir}/bad-cert"
mkdir -p "${bad_cert_dir}"
bad_cert_file="${tmpdir}/bad-server.crt"
: > "${bad_cert_file}"
chmod 666 "${bad_cert_file}"

if render "${bad_cert_dir}" \
  BASHIO_SSL_ENABLED=true \
  BASHIO_SSL_CERTFILE="${bad_cert_file}" \
  BASHIO_SSL_KEYFILE="${key_file}" \
  BASHIO_HOST_NETWORK=true \
  BASHIO_ALLOWLIST=$'10.0.0.0/24'; then
  exit 1
fi

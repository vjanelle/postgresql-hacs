#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

trace_file="${tmpdir}/trace.log"
mkdir -p "${tmpdir}/bin"

cat >"${tmpdir}/bashio" <<'EOF'
#!/usr/bin/env bash

bashio::log.warning() {
  printf 'WARN: %s\n' "$*" >&2
}

bashio::config.exists() {
  [[ "$1" == "databases[0].owner" ]]
}

bashio::config() {
  local key="$1"

  if [[ "$key" == "memberships|length" ]]; then
    printf '1\n'
  elif [[ "$key" == "memberships|keys" ]]; then
    printf '0\n'
  elif [[ "$key" == "memberships[0].group" ]]; then
    printf 'declared_group\n'
  elif [[ "$key" == "memberships[0].member" ]]; then
    printf 'declared_member\n'
  elif [[ "$key" == "grants|length" ]]; then
    printf '1\n'
  elif [[ "$key" == "grants|keys" ]]; then
    printf '0\n'
  elif [[ "$key" == "grants[0].database" ]]; then
    printf 'appdb\n'
  elif [[ "$key" == "grants[0].role" ]]; then
    printf 'app_role\n'
  elif [[ "$key" == "grants[0].privileges" ]]; then
    printf 'SELECT\n'
  elif [[ "$key" == "databases[0].owner" ]]; then
    printf 'app_owner\n'
  else
    printf '0\n'
  fi
}
EOF
chmod +x "${tmpdir}/bashio"

cat >"${tmpdir}/bin/runuser" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'RUNUSER:%s\n' "$*" >>"${TRACE_FILE}"

while [[ $# -gt 0 && "$1" != "--" ]]; do
  shift
done

if [[ "${1:-}" == "--" ]]; then
  shift
fi

exec "$@"
EOF
chmod +x "${tmpdir}/bin/runuser"

cat >"${tmpdir}/bin/psql" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

sql=""
file=""

printf 'PSQL:%s\n' "$*" >>"${TRACE_FILE}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --command)
      sql="$2"
      shift 2
      ;;
    --file)
      file="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -n "${file}" && "${file}" == *drift.sql ]]; then
  printf 'membership\tdeclared_group\tdeclared_member\tMEMBER\n'
  printf 'membership\textra_group\textra_member\tMEMBER\n'
  printf 'database\tappdb\tapp_role\tCONNECT\n'
  printf 'database\tappdb\tPUBLIC\tCONNECT\n'
  printf 'schema\tpublic\tPUBLIC\tUSAGE\n'
  exit 0
fi

case "${sql}" in
  *"SELECT 1 FROM pg_database WHERE datname = 'appdb';"*)
    printf '1\n'
    ;;
  *"SELECT pg_get_userbyid(datdba) FROM pg_database WHERE datname = 'appdb';"*)
    printf 'app_owner\n'
    ;;
esac
EOF
chmod +x "${tmpdir}/bin/psql"

cat >"${tmpdir}/bin/psql-apply-file" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'APPLY:%s\n' "$*" >>"${TRACE_FILE}"
EOF
chmod +x "${tmpdir}/bin/psql-apply-file"

PATH="${tmpdir}/bin:${PATH}" \
TRACE_FILE="${trace_file}" \
BASHIO_LIB="${tmpdir}/bashio" \
RUNUSER_BIN="runuser" \
PSQL_BIN="psql" \
PSQL_APPLY_FILE="${tmpdir}/bin/psql-apply-file" \
bash rootfs/usr/bin/provision-postgres >/dev/null 2>"${tmpdir}/stderr.log"

grep -q "drift.sql" "${trace_file}"
grep -q "WARN: postgres drift: object_type=membership context=extra_group subject_role=extra_member extra_privilege=MEMBER" "${tmpdir}/stderr.log"
grep -q "WARN: postgres drift: object_type=database context=appdb subject_role=PUBLIC extra_privilege=CONNECT" "${tmpdir}/stderr.log"
grep -q "WARN: postgres drift: object_type=schema context=public subject_role=PUBLIC extra_privilege=USAGE" "${tmpdir}/stderr.log"
test "$(grep -c '^WARN: postgres drift:' "${tmpdir}/stderr.log")" -eq 3
grep -q "v1 is additive-only" DOCS.md

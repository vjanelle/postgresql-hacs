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
  case "$1" in
    roles[0].password|roles[0].login|databases[0].owner)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

bashio::config() {
  local key="$1"

  if [[ "$key" == "roles|length" ]]; then
    printf '1\n'
  elif [[ "$key" == "roles|keys" ]]; then
    printf '0\n'
  elif [[ "$key" == "roles[0].username" ]]; then
    printf 'app_login\n'
  elif [[ "$key" == "roles[0].login" ]]; then
    printf 'true\n'
  elif [[ "$key" == "roles[0].password" ]]; then
    printf 'resolved-secret-token\n'
  elif [[ "$key" == "memberships|length" ]]; then
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
  elif [[ "$key" == "databases|length" ]]; then
    printf '1\n'
  elif [[ "$key" == "databases|keys" ]]; then
    printf '0\n'
  elif [[ "$key" == "databases[0].name" ]]; then
    printf 'appdb\n'
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
db_name=""
include_memberships=""
include_database_privileges=""
include_schema_privileges=""

printf 'PSQL:%s\n' "$*" >>"${TRACE_FILE}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dbname)
      db_name="$2"
      shift 2
      ;;
    -v)
      case "$2" in
        include_memberships=1)
          include_memberships=1
          ;;
        include_database_privileges=1)
          include_database_privileges=1
          ;;
        include_schema_privileges=1)
          include_schema_privileges=1
          ;;
      esac
      shift 2
      ;;
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
  drift_sql="$(cat rootfs/usr/share/postgresql/bootstrap/drift.sql)"
  if [[ -n "${include_memberships}" ]]; then
    printf 'membership\tdeclared_group\tdeclared_member\tMEMBER\n'
    printf 'membership\textra_group\textra_member\tMEMBER\n'
  fi
  if [[ -n "${include_database_privileges}" ]]; then
    printf 'database\t%s\tapp_role\tCONNECT\n' "${db_name}"
    printf 'database\t%s\tapp_owner\tCONNECT\n' "${db_name}"
    printf 'database\ttemplate1\tPUBLIC\tCONNECT\n'
    if ! grep -q 'd.datacl IS NOT NULL' <<<"${drift_sql}"; then
      printf 'database\t%s\tPUBLIC\tCONNECT\n' "${db_name}"
    fi
  fi
  if [[ -n "${include_schema_privileges}" ]]; then
    printf 'schema\tpublic\tapp_role\tUSAGE\n'
    printf 'schema\tpublic\tapp_owner\tUSAGE\n'
    printf 'schema\tinformation_schema\tPUBLIC\tUSAGE\n'
    if ! grep -q 'n.nspacl IS NOT NULL' <<<"${drift_sql}"; then
      printf 'schema\tpublic\tPUBLIC\tUSAGE\n'
    fi
  fi
  exit 0
fi

case "${sql}" in
  *"SELECT 1 FROM pg_database WHERE datname = 'appdb';"*)
    printf '1\n'
    ;;
  *"SELECT pg_get_userbyid(datdba) FROM pg_database WHERE datname = 'appdb';"*)
    printf 'app_owner\n'
    ;;
  *"SELECT pg_get_userbyid(nspowner) FROM pg_namespace WHERE nspname = 'public';"*)
    printf 'public_owner\n'
    ;;
esac
EOF
chmod +x "${tmpdir}/bin/psql"

cat >"${tmpdir}/bin/psql-apply-file" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'APPLY:%s\n' "${1:-}" >>"${TRACE_FILE}"
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
grep -q "SELECT pg_get_userbyid(nspowner) FROM pg_namespace WHERE nspname = 'public';" "${trace_file}"
! grep -q "resolved-secret-token" "${trace_file}"
! grep -q "resolved-secret-token" "${tmpdir}/stderr.log"
grep -q "WARN: postgres drift: object_type=membership context=extra_group subject_role=extra_member extra_privilege=MEMBER" "${tmpdir}/stderr.log"
grep -q "WARN: postgres drift: object_type=database context=appdb subject_role=PUBLIC extra_privilege=CONNECT" "${tmpdir}/stderr.log"
grep -q "WARN: postgres drift: database=appdb object_type=schema context=public subject_role=app_owner extra_privilege=USAGE" "${tmpdir}/stderr.log"
grep -q "WARN: postgres drift: database=appdb object_type=schema context=public subject_role=PUBLIC extra_privilege=USAGE" "${tmpdir}/stderr.log"
test "$(grep -c '^WARN: postgres drift:' "${tmpdir}/stderr.log")" -eq 4
! grep -q "context=appdb subject_role=app_owner" "${tmpdir}/stderr.log"
! grep -q "context=template1" "${tmpdir}/stderr.log"
! grep -q "context=information_schema" "${tmpdir}/stderr.log"
grep -q "v1 is additive-only" DOCS.md

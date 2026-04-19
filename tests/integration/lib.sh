#!/usr/bin/env bash
set -euo pipefail

integration::container_bin() {
  if [[ -n "${ADDON_CONTAINER_BIN:-}" ]]; then
    printf '%s\n' "${ADDON_CONTAINER_BIN}"
    return
  fi

  if command -v podman >/dev/null 2>&1; then
    printf 'podman\n'
    return
  fi

  printf 'docker\n'
}

integration::require_container_bin() {
  local bin
  bin="$(integration::container_bin)"

  if ! command -v "${bin}" >/dev/null 2>&1; then
    printf 'missing container runtime: %s\n' "${bin}" >&2
    return 1
  fi
}

integration::repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

integration::host_arch() {
  case "$(uname -m)" in
    x86_64)
      printf 'amd64'
      ;;
    aarch64|arm64)
      printf 'aarch64'
      ;;
    armv7l|armv7*)
      printf 'armv7'
      ;;
    armhf)
      printf 'armhf'
      ;;
    i386|i686)
      printf 'i386'
      ;;
    *)
      printf 'amd64'
      ;;
  esac
}

integration::build_from() {
  printf '%s\n' "${ADDON_BUILD_FROM:-ghcr.io/home-assistant/$(integration::host_arch)-base-debian:bookworm}"
}

integration::image_tag() {
  printf '%s\n' "${ADDON_IMAGE_TAG:-postgresql18-addon-integration:local}"
}

integration::build_image() {
  local image_tag
  image_tag="$(integration::image_tag)"
  integration::require_container_bin
  local container_bin
  container_bin="$(integration::container_bin)"

  if ! "${container_bin}" image inspect "${image_tag}" >/dev/null 2>&1; then
    "${container_bin}" build \
      --build-arg BUILD_FROM="$(integration::build_from)" \
      -t "${image_tag}" \
      "$(integration::repo_root)"
  fi
}

integration::container_name() {
  printf '%s-%s-%s\n' "postgresql18-addon-it" "$1" "$$"
}

integration::cleanup_container() {
  local container="$1"
  local container_bin
  container_bin="$(integration::container_bin)"

  "${container_bin}" rm -f "${container}" >/dev/null 2>&1 || true
}

integration::start_container() {
  local container="$1"
  local options_file="$2"
  local data_dir="$3"
  shift 3
  integration::require_container_bin
  local container_bin
  container_bin="$(integration::container_bin)"

  mkdir -p "${data_dir}"

  "${container_bin}" run -d \
    --name "${container}" \
    --rm \
    --shm-size=256m \
    --tmpfs /run \
    -v "${data_dir}:/data" \
    -v "${options_file}:/data/options.json:ro" \
    "$@" \
    "$(integration::image_tag)"
}

integration::psql() {
  local container="$1"
  local db="$2"
  local user="$3"
  local password="$4"
  local sslmode="$5"
  local host="$6"
  local sql="$7"
  local container_bin
  container_bin="$(integration::container_bin)"

  "${container_bin}" exec \
    -e PGPASSWORD="${password}" \
    -e PGSSLMODE="${sslmode}" \
    "${container}" \
    psql \
      --no-psqlrc \
      --quiet \
      --tuples-only \
      --no-align \
      --set=ON_ERROR_STOP=1 \
      --host "${host}" \
      --username "${user}" \
      --dbname "${db}" \
      --command "${sql}"
}

integration::wait_for_psql() {
  local container="$1"
  local db="$2"
  local user="$3"
  local password="$4"
  local sslmode="$5"
  local host="$6"
  local sql="$7"
  local attempt

  for attempt in $(seq 1 120); do
    if integration::psql "${container}" "${db}" "${user}" "${password}" "${sslmode}" "${host}" "${sql}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  return 1
}

integration::prepare_ssl_dir() {
  local ssl_dir="$1"
  integration::require_container_bin
  local container_bin
  container_bin="$(integration::container_bin)"

  "${container_bin}" run --rm \
    -v "${ssl_dir}:${ssl_dir}" \
    --entrypoint bash \
    "$(integration::image_tag)" \
    -lc "chown postgres:postgres '${ssl_dir}/server.crt' '${ssl_dir}/server.key' && chmod 640 '${ssl_dir}/server.crt' && chmod 600 '${ssl_dir}/server.key'"
}

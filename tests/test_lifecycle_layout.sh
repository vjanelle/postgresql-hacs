#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

for path in \
  rootfs/etc/s6-overlay/s6-rc.d/postgres-pre/run \
  rootfs/etc/s6-overlay/s6-rc.d/postgres-pre/type \
  rootfs/etc/s6-overlay/s6-rc.d/postgres-pre/dependencies.d/base \
  rootfs/etc/s6-overlay/s6-rc.d/postgres-core/run \
  rootfs/etc/s6-overlay/s6-rc.d/postgres-core/type \
  rootfs/etc/s6-overlay/s6-rc.d/postgres-core/dependencies.d/postgres-pre \
  rootfs/etc/s6-overlay/s6-rc.d/postgres-post/run \
  rootfs/etc/s6-overlay/s6-rc.d/postgres-post/type \
  rootfs/etc/s6-overlay/s6-rc.d/postgres-post/dependencies.d/postgres-core \
  rootfs/etc/s6-overlay/s6-rc.d/postgres/type \
  rootfs/etc/s6-overlay/s6-rc.d/postgres/contents.d/postgres-pre \
  rootfs/etc/s6-overlay/s6-rc.d/postgres/contents.d/postgres-core \
  rootfs/etc/s6-overlay/s6-rc.d/postgres/contents.d/postgres-post \
  rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/postgres \
  rootfs/usr/local/bin/provisioning-entrypoint
do
  test -f "$path"
done

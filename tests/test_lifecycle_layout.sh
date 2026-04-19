#!/usr/bin/env bash
set -euo pipefail

for path in \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-pre/run \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-pre/type \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-pre/dependencies.d/base \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-core/run \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-core/type \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-core/dependencies.d/postgres-pre \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-post/run \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-post/type \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-post/dependencies.d/postgres-core \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres/type \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres/contents.d/postgres-pre \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres/contents.d/postgres-core \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres/contents.d/postgres-post \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/postgres \
  postgresql18-addon/rootfs/usr/local/bin/provisioning-entrypoint
do
  test -f "$path"
done

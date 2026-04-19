#!/usr/bin/env bash
set -euo pipefail

for path in \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-pre/run \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-core/run \
  postgresql18-addon/rootfs/etc/s6-overlay/s6-rc.d/postgres-post/run
do
  test -f "$path"
done

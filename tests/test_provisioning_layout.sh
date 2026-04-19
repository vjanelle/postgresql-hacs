#!/usr/bin/env bash
set -euo pipefail

for path in \
  postgresql18-addon/rootfs/usr/bin/provision-postgres \
  postgresql18-addon/rootfs/usr/bin/psql-apply-file \
  postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/roles.sql \
  postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/memberships.sql \
  postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/databases.sql \
  postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/extensions.sql \
  postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/schemas.sql \
  postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/grants.sql \
  postgresql18-addon/rootfs/usr/share/postgresql/bootstrap/drift.sql
do
  test -f "$path"
done

for path in \
  postgresql18-addon/rootfs/usr/bin/provision-postgres \
  postgresql18-addon/rootfs/usr/bin/psql-apply-file \
  postgresql18-addon/rootfs/usr/local/bin/provisioning-entrypoint
do
  test -x "$path"
done

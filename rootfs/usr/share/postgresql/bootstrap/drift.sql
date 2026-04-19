\if :{?include_memberships}
-- undeclared memberships
SELECT
  'membership' AS object_type,
  g.rolname AS object_context,
  u.rolname AS subject_role,
  'MEMBER' AS extra_privilege
FROM pg_auth_members m
JOIN pg_roles g ON g.oid = m.roleid
JOIN pg_roles u ON u.oid = m.member
ORDER BY 1, 2, 3;
\endif

\if :{?include_database_privileges}
-- undeclared database privileges
SELECT
  'database' AS object_type,
  d.datname AS object_context,
  COALESCE(pg_get_userbyid(p.grantee), 'PUBLIC') AS subject_role,
  p.privilege_type AS extra_privilege
FROM pg_database d
JOIN LATERAL aclexplode(COALESCE(d.datacl, acldefault('d', d.datdba))) AS p ON true
WHERE d.datname = current_database()
  AND p.privilege_type IS NOT NULL
ORDER BY 1, 2, 3, 4;
\endif

\if :{?include_schema_privileges}
-- undeclared schema privileges
SELECT
  'schema' AS object_type,
  n.nspname AS object_context,
  COALESCE(pg_get_userbyid(p.grantee), 'PUBLIC') AS subject_role,
  p.privilege_type AS extra_privilege
FROM pg_namespace n
JOIN LATERAL aclexplode(COALESCE(n.nspacl, acldefault('n', n.nspowner))) AS p ON true
WHERE n.nspname = 'public'
  AND p.privilege_type IS NOT NULL
ORDER BY 1, 2, 3, 4;
\endif

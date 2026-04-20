SELECT set_config('haos.group_name', :'group_name', false);
SELECT set_config('haos.member_name', :'member_name', false);

DO $$
DECLARE
  group_name text := current_setting('haos.group_name');
  member_name text := current_setting('haos.member_name');
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_auth_members m
    JOIN pg_roles g ON g.oid = m.roleid
    JOIN pg_roles u ON u.oid = m.member
    WHERE g.rolname = group_name
      AND u.rolname = member_name
  ) THEN
    EXECUTE format('GRANT %I TO %I', group_name, member_name);
  END IF;
END
$$;

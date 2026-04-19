DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'role_name') THEN
    EXECUTE format(
      'ALTER ROLE %I %s%s',
      :'role_name',
      CASE WHEN :'role_login'::boolean THEN 'LOGIN' ELSE 'NOLOGIN' END,
      CASE WHEN NULLIF(:'role_password', '') IS NULL THEN '' ELSE format(' PASSWORD %L', :'role_password') END
    );
  ELSE
    EXECUTE format(
      'CREATE ROLE %I WITH %s%s',
      :'role_name',
      CASE WHEN :'role_login'::boolean THEN 'LOGIN' ELSE 'NOLOGIN' END,
      CASE WHEN NULLIF(:'role_password', '') IS NULL THEN '' ELSE format(' PASSWORD %L', :'role_password') END
    );
  END IF;
END
$$;

SELECT set_config('haos.role_name', :'role_name', false);
SELECT set_config('haos.role_login', :'role_login', false);
SELECT set_config('haos.role_password', :'role_password', false);

DO $$
DECLARE
  role_name text := current_setting('haos.role_name');
  role_login boolean := current_setting('haos.role_login')::boolean;
  role_password text := current_setting('haos.role_password');
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = role_name) THEN
    EXECUTE format(
      'ALTER ROLE %I %s%s',
      role_name,
      CASE WHEN role_login THEN 'LOGIN' ELSE 'NOLOGIN' END,
      CASE WHEN NULLIF(role_password, '') IS NULL THEN '' ELSE format(' PASSWORD %L', role_password) END
    );
  ELSE
    EXECUTE format(
      'CREATE ROLE %I WITH %s%s',
      role_name,
      CASE WHEN role_login THEN 'LOGIN' ELSE 'NOLOGIN' END,
      CASE WHEN NULLIF(role_password, '') IS NULL THEN '' ELSE format(' PASSWORD %L', role_password) END
    );
  END IF;
END
$$;

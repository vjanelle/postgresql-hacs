SELECT set_config('haos.grant_role', :'grant_role', false);
SELECT set_config('haos.grant_privileges', :'grant_privileges', false);

DO $$
DECLARE
  grant_role text := current_setting('haos.grant_role');
BEGIN
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', current_database(), grant_role);
END
$$;

DO $$
DECLARE
  grant_role text := current_setting('haos.grant_role');
BEGIN
  EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', grant_role);
END
$$;

DO $$
DECLARE
  grant_role text := current_setting('haos.grant_role');
  grant_privileges text := current_setting('haos.grant_privileges');
BEGIN
  EXECUTE format(
    'GRANT %s ON ALL TABLES IN SCHEMA public TO %I',
    grant_privileges,
    grant_role
  );
END
$$;

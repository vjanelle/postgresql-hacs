SELECT set_config('haos.db_owner', :'db_owner', false);

DO $$
DECLARE
  db_owner text := current_setting('haos.db_owner');
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'public') THEN
    EXECUTE 'CREATE SCHEMA public';
  END IF;

  IF NULLIF(db_owner, '') IS NOT NULL THEN
    EXECUTE format('ALTER SCHEMA public OWNER TO %I', db_owner);
  END IF;
END
$$;

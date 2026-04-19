DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'public') THEN
    EXECUTE 'CREATE SCHEMA public';
  END IF;

  IF NULLIF(:'db_owner', '') IS NOT NULL THEN
    EXECUTE format('ALTER SCHEMA public OWNER TO %I', :'db_owner');
  END IF;
END
$$;

SELECT set_config('haos.db_name', :'db_name', false);
SELECT set_config('haos.db_owner', :'db_owner', false);

DO $$
DECLARE
  db_name text := current_setting('haos.db_name');
  db_owner text := current_setting('haos.db_owner');
BEGIN
  IF NULLIF(db_owner, '') IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM pg_database
      WHERE datname = db_name
        AND pg_get_userbyid(datdba) IS DISTINCT FROM db_owner
    ) THEN
    EXECUTE format('ALTER DATABASE %I OWNER TO %I', db_name, db_owner);
  END IF;
END
$$;

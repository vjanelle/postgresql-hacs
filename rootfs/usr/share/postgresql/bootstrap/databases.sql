DO $$
BEGIN
  IF NULLIF(:'db_owner', '') IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM pg_database
      WHERE datname = :'db_name'
        AND pg_get_userbyid(datdba) IS DISTINCT FROM :'db_owner'
    ) THEN
    EXECUTE format('ALTER DATABASE %I OWNER TO %I', :'db_name', :'db_owner');
  END IF;
END
$$;

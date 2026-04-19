DO $$
BEGIN
  IF NOT has_database_privilege(:'grant_role', current_database(), 'CONNECT') THEN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', current_database(), :'grant_role');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT has_schema_privilege(:'grant_role', 'public', 'USAGE') THEN
    EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', :'grant_role');
  END IF;
END
$$;

DO $$
BEGIN
  EXECUTE format(
    'GRANT %s ON ALL TABLES IN SCHEMA public TO %I',
    :'grant_privileges',
    :'grant_role'
  );
END
$$;

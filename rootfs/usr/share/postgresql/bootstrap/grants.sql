DO $$
BEGIN
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', current_database(), :'grant_role');
END
$$;

DO $$
BEGIN
  EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', :'grant_role');
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

\set ON_ERROR_STOP on

SELECT format(
  'CREATE DATABASE %I%s',
  :'db_name',
  CASE
    WHEN NULLIF(:'db_owner', '') IS NULL THEN ''
    ELSE format(' OWNER %I', :'db_owner')
  END
)
WHERE NOT EXISTS (
  SELECT 1
  FROM pg_database
  WHERE datname = :'db_name'
)
\gexec

SELECT format(
  'ALTER DATABASE %I OWNER TO %I',
  :'db_name',
  :'db_owner'
)
WHERE NULLIF(:'db_owner', '') IS NOT NULL
  AND EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = :'db_name'
      AND pg_get_userbyid(datdba) IS DISTINCT FROM :'db_owner'
  )
\gexec

#!/bin/bash
# psql into the DEMO database only (connection details in demo/.env.demo).
set -euo pipefail
cd "$(dirname "$0")"
set -a; source .env.demo; set +a
export PGPASSWORD=$DEMO_DB_PASSWORD PGTZ=UTC
exec /Applications/Postgres.app/Contents/Versions/17/bin/psql -X -v ON_ERROR_STOP=1 \
  "host=$DEMO_DB_HOST port=5432 dbname=postgres user=postgres.$DEMO_PROJECT_REF sslmode=require" "$@"

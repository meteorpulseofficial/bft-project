#!/bin/bash
set -e
export PATH=/opt/homebrew/opt/postgresql@17/bin:$PATH
DB=${1:-audit}
P="psql -h /tmp/pg -p 54329 -U postgres -v ON_ERROR_STOP=1 -q"
$P -c "drop database if exists $DB" -c "create database $DB"
for f in /Users/aaron/dev/bft-coach-hub/app/supabase/tests/00_supabase_stub.sql /Users/aaron/dev/bft-coach-hub/app/supabase/migrations/*.sql; do $P -d $DB -f $f >/dev/null; done
$P -d $DB -f "$(dirname "$0")/seed.sql"
echo built $DB

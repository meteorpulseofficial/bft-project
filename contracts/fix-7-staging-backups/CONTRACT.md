# Fix #7 (no staging copy, no backups): contract

**Version:** 2 · **Frozen:** v2, 2026-11-22, by Claude as Aaron's IT (technical calls delegated) · **Owner:** the db lane (ops kit) ·
**Last changed:** 2026-11-22 · by Claude as Aaron's IT (technical calls delegated; money and
account decisions to Kelvin)

## What changes (for Kelvin)

Today every push to `main` goes straight to live coaches, and every SQL file is pasted by hand into
the live database. Supabase is on the Free plan: no backups, and it pauses when idle. This fix adds
a small kit to the repo (folder `ops/`) so that (1) a second Supabase project with fake data can act
as **staging**, wired to a `staging` branch on Vercel; (2) database changes are applied by a script
that keeps a record of what ran, refuses edited or out-of-order files, and won't touch production
until staging has run exactly the same files; (3) the database can be backed up (encrypted) and the
backup proven restorable; (4) a nightly GitHub backup that stays switched off until you add its
secrets. The parts only you can do (Supabase Pro, creating the staging project, Vercel settings,
GitHub secrets, inviting us) are a step-by-step list in `ops/README.md`.

## Today

- Migrations `supabase/migrations/*.sql`: 0001–0007 Kelvin's (some without BEGIN/COMMIT), 0008–0015
  ours (each one transaction with BEGIN/COMMIT). Run by hand in the SQL editor. No record of what ran.
- Our demo kit (`demo/` outside the repo): seed.sql, create-users.mjs, lib.mjs, psql-demo.sh —
  fake people (example.com), two studios, every role. Reuse, don't rewrite from scratch.
- Local test runner `supabase/tests/run.sh` with an auth stub (`tests/00_supabase_stub.sql`).

## Decisions (orchestrator, v1)

- D1. Everything new lives under `ops/` in the repo (plus `.gitignore` lines and one workflow file).
  No app code change, no new migration in `supabase/migrations/`.
- D2. **Connections** come from `ops/.env.<target>` files (gitignored; template `ops/env.example`):
  target names `local`, `demo`, `staging`, `production`. Passwords never on the command line, never
  echoed, never in logs (use PGPASSWORD / service file from the env file).
- D3. **`ops/migrate.sh <target> [--dry-run] [--baseline <version>]`.** Ledger table
  `ops.schema_migrations(version, filename, sha256, applied_at, applied_by)` in a schema `ops` that
  anon/authenticated cannot read or write (not exposed through the API). Applies pending files in
  version order, each file as one transaction (works whether or not the file has its own
  BEGIN/COMMIT — owner decides how), records the row in the same transaction, stops at the first
  error (nothing of that file kept, later files not run, exit non-zero). Refuses if an applied file's
  checksum changed, or if a file older than the newest applied one is still pending (out of order).
  `--baseline <version>` records every file up to that version as applied without running it (for a
  database where they were pasted by hand), after showing the list and asking for confirmation.
- D4. **Production guard.** Target `production` requires (a) typing the production project ref to
  confirm, and (b) that staging's ledger already contains every file about to run with the same
  checksum; otherwise it refuses (override flag allowed only with a second typed confirmation, and
  it says so loudly).
- D5. **Staging seed** `ops/seed/` — port of the demo seed + user creation: fake people at
  example.com, two studios, every role, a Lead, a strike, a cancelled class, a challenge. Refuses to
  run unless the target is `local`/`demo`/`staging` AND the database has no profile whose email is
  outside example.com (guard against seeding production). Idempotent or clearly refuses a second run.
- D6. **Backup** `ops/backup.sh <target> <out-dir>`: pg_dump (custom format) of the data that matters
  — `public` and the `auth` schema's data (users/identities, so logins survive) — plus a manifest of
  row counts per table; output encrypted with a passphrase from the env file (openssl, AES-256,
  pbkdf2), file mode 600, refuses an out-dir inside the repo. Must work with the pg_dump installed
  here (Postgres.app 17) against Supabase's server version (check it).
- D7. **Restore check** `ops/restore-check.sh <backup-file>`: decrypts, restores into a new scratch
  local database, compares row counts with the manifest, prints PASS/FAIL, drops the scratch db.
  Wrong passphrase → clear failure. `ops/README.md` also documents restoring into a fresh Supabase
  project (steps; not run against a real one unless on our demo).
- D8. **Nightly backup workflow** `.github/workflows/nightly-backup.yml`: daily, runs backup.sh,
  uploads the encrypted file as a private artifact (retention 14 days). If its secrets are missing
  it logs "not configured" and exits successfully (merging it changes nothing until Kelvin turns it
  on). Side effect noted: a daily query also stops a Free project from pausing.
- D9. `ops/README.md` (plain English, for Kelvin): what staging is; the one-time setup in order
  (Supabase Pro on production — his money decision, ~US$25/month, daily backups kept 7 days, no
  pausing; create the staging project; Vercel: `staging` branch Preview env vars to staging
  Supabase, production unchanged, NEXT_PUBLIC_SITE_URL per environment; GitHub secrets for the
  nightly backup; invite us with least access); the release flow (PR → staging → check → main;
  migrate staging → check → migrate production); baseline instructions for production
  (0001–0007 pasted by hand; 0008+ to run via the script); how to back up and restore.
- D10. Verification only on local Postgres and Aaron's demo project (`demo/.env.demo`); never
  Kelvin's anything.

## v2 decisions (after the checker's pre-mortem, `attack-list.md`; these win over v1)

- E1 (S1, S2, F6). Runner transaction model: each file runs in ONE transaction that the runner
  opens (`psql -X -v ON_ERROR_STOP=1 --single-transaction`), with a single top-level `begin;` and
  `commit;` line removed from the file text first (exact lines, case-insensitive, whitespace
  tolerant); a file with any other transaction control (more than one begin/commit, rollback,
  savepoint at top level, `\` meta-commands) is refused. Inside that same transaction, before the
  file: `pg_advisory_xact_lock(<fixed key>)`, then re-check the ledger and stop if the version is
  already recorded; after the file: insert the ledger row. So a crash or a concurrent run can never
  apply a file twice (A-03, A-04, also through the transaction pooler). `lock_timeout` 10s,
  `statement_timeout` 10min, set per transaction. Checksum = sha256 of the file bytes as committed.
- E2 (S3). A committed, non-secret `ops/production-ref` holds the production project ref
  (placeholder until Kelvin fills it; production target refuses while it's a placeholder). Every
  non-production target refuses a connection whose host or user contains that ref; production
  refuses one that doesn't. Target names: exact whitelist `local|demo|staging|production`.
  Confirmations read from /dev/tty only (no TTY → refuse).
- E3 (S4). Staging may be a Free project; README says wake it before a release. Production runs
  refuse with a clear reason if staging is unreachable.
- E4 (S5). Real-people guard runs before ANY write, in the user-creation step too: refuses if
  auth.users or profile_contacts has any email whose lowercased domain is not exactly `example.com`,
  or any profile with a NULL/missing contact email (other than the 0002 bootstrap rows the seed is
  about to replace — owner decides how to tell them apart safely and documents it). Local seeding
  inserts into the stub's auth.users directly; staging/demo use the admin API with a service-role key
  from the env file (added to D2's key list). README: seed straight after migrating staging (0002
  puts Kelvin's real contact rows there until the seed replaces them).
- E5 (S6). Backup excludes auth data for sessions, refresh_tokens, one_time_tokens, flow_state,
  audit_log_entries, mfa_challenges and saml/oauth state tables (schema kept, data excluded); keeps
  users, identities, mfa_factors. Also dumps `storage` schema object metadata if present.
- E6 (S7). README states plainly: Storage FILES (e.g. absence evidence uploads) are not in this
  backup nor in Supabase Pro's daily backup; gives Kelvin the options. Recorded as an open item.
- E7 (S8, A-31, A-34). Manifest: exact count(*) per table from the same snapshot as the dump
  (repeatable-read + exported snapshot), the table list, and sha256 of the plaintext dump; manifest
  is encrypted inside the same bundle or alongside (owner chooses; no counts in clear text).
  Restore-check: local socket only, ignores PG* env and ops env files, unique scratch-db prefix,
  drops only its own db (also on Ctrl-C / failure); pre-creates extensions + pgcrypto + uuid-ossp
  and the anon/authenticated/service_role roles if missing; drops `public` in the scratch db first;
  ANY other pg_restore error = FAIL; table set must equal the manifest; counts must match; plaintext
  sha256 must match (wrong passphrase never PASSes).
- E8 (S9). README's "restore into a fresh Supabase project" section is labelled UNTESTED unless
  proven on the demo project; auth data only into users/identities; never replay
  auth.schema_migrations.
- E9 (S10, A-41..A-43). Workflow: all secrets missing → success with a `::warning::`; some set →
  fail; pg_dump 17 from a postgres:17 container or PGDG with an explicit version check; session
  pooler host; triggers schedule + workflow_dispatch only; permissions contents: read; concurrency
  group; actions pinned to full SHAs; artifact = encrypted file(s) only, retention 14 days; secrets
  are separate fields (no URL secret). README: artifacts are downloadable by anyone with repo read
  access — the repo must stay private (question for Kelvin); scheduled runs only from the default
  branch.
- E10 (S11). README Vercel steps: ALL Preview deployments → staging Supabase (not just the staging
  branch), Deployment Protection on previews, staging Supabase Auth Site URL / redirect URLs = the
  staging domain. Question for Kelvin: is Supabase's GitHub integration or `supabase db push` in use
  (a second migration ledger)?
- E11 (S12). `ops/schema-diff.sh <targetA> <targetB>`: read-only `pg_dump --schema-only` of public
  from both, normalised, diffed. README: after baselining production, run it production vs staging
  and send us the output before running 0008+; ask Kelvin whether any of 0008–0015 were already
  pasted.
- E12 (S13, S14, S16, S17). Env files parsed as KEY=VALUE (never `source`d), must be mode 600;
  password passed via a temporary 600 pgpass/service file or child-only env, never a URL or argv.
  bash 3.2 compatible, `set -euo pipefail`, `umask 077`, `shasum -a 256`, fixed `-iter` (recorded),
  quote every path. .gitignore adds `*.dump`, `*.enc`, `ops/backups/`; template is `ops/env.example`.
  Ledger `applied_by` = database user only (plus override flag column).
- E13 (S15). R-01 uses `psql -f` per test on the migrated db (run.sh drops dbs). R-12 limited to
  ops/ commands; Kelvin-only steps marked "not run, Kelvin step". New R-tests below.

## Acceptance tests (v1; see v2 additions)

- R-01 migrate on an empty local db (with the auth stub) applies 0001–0015 in order; ledger has 15
  rows with checksums; then tests 10–98 pass on that db.
- R-02 re-run → nothing applied, exit 0. `--dry-run` lists pending, changes nothing.
- R-03 a broken file (temp copy of the folder) → stops, exit non-zero, no partial objects, ledger
  unchanged, later files not run.
- R-04 an applied file edited → refused (checksum). Out-of-order pending file → refused.
- R-05 baseline to 0007 on a db where 0001–0007 were run by hand → ledger 7 rows; next run applies
  only 0008+.
- R-06 production target: no/incorrect confirmation → refused; staging behind or checksum mismatch
  → refused. (Tested with a fake "production" pointing at a local db.)
- R-07 no password in argv, stdout/stderr or files; missing env file → clear error.
- R-08 backup of the demo project → encrypted file + manifest; restore-check → PASS with matching
  counts incl. auth users; wrong passphrase → clear FAIL; out-dir inside the repo → refused.
- R-09 seed on a fresh local db → every role present; on a db with a non-example.com profile →
  refused; target `production` → refused.
- R-10 workflow without secrets → exits 0 with "not configured" (simulate the script path locally);
  YAML valid.
- R-11 on the demo: ledger schema not readable or writable by anon/authenticated through the API.
- R-12 every command in ops/README.md was actually run (local or demo) by the checker.

## What must NOT change

App code, existing migrations and tests, the demo kit outside the repo, Kelvin's production.

### v2 acceptance additions

- R-13 crash between a file's statements and its ledger row, and two concurrent runs (incl. via the
  6543 transaction pooler emulation if possible) → never a double apply (A-03, A-04).
- R-14 staging env file pointing at the production ref → refused; production env identity mismatch
  → refused (A-19, A-20).
- R-15 user creation refused before any account on a db with real people (A-24, A-25).
- R-16 no plaintext dump left anywhere after success, failure or Ctrl-C (A-29).
- R-17 restore-check: F3 broken-restore case → FAIL; wrong passphrase ×1000 → all FAIL; local only
  (A-32..A-35).
- R-18 bash 3.2 (macOS) and a Linux bash run of the scripts' syntax (`bash -n`), no bash-4 features.

# Fix #7: checker's pre-mortem (2026-11-22 08:52 UTC, verbatim in substance)

Facts: F1 demo = PG 17.12, local pg_dump 17.12, dump via session pooler 5432 works (3.6 s).
F2 demo postgres not superuser; can read auth (27 tables incl. sessions, refresh_tokens,
one_time_tokens, mfa_factors, audit_log_entries). F3 plain pg_restore into empty local db: 23 errors
(no `extensions` schema → studios + 21 objects missing) yet counts of surviving tables match →
count-only check would PASS a broken restore; pre-creating extensions+pgcrypto+uuid-ossp leaves 1
harmless error ("public" exists); roles anon/authenticated must exist. F4 pg_dump writes 0644.
F5 0001–0008 no BEGIN/COMMIT, 0009–0015 one each; nothing non-transactional; 0010/0012 need a txn;
0007 touches storage; 0002 NOT idempotent and holds Kelvin's real email/phone/company details.
F6 psql -1 on a file with its own COMMIT: later statements autocommit, partial objects survive.
F7 new schema `ops` gets no anon/authenticated grants; anon has USAGE on auth; timeouts anon 3s,
authenticated 8s, pooler 2min. F8 test 70 covers only public. F9 LibreSSL 3.3.6 enc supports
-pbkdf2 -iter; cross-decrypts with OpenSSL when -iter fixed; CBC wrong passphrase exits 0 ~1/256;
failed decrypt leaves -out file. F10 bash 3.2, shasum present, no timeout/gh. F11 `.env*` ignored
at any depth but `!.env.example`; nothing ignores *.dump/*.enc. F12 demo create-users has no
real-people guard; seed guard case-sensitive, NULL/missing contact slip; seed never run on 0008–0015.

Attacks A-01..A-44 (full text in the checker's report, summarised):
Migrate: A-01 empty db → 15 rows, sha256 = shasum; tests 10–98 via psql -f on that db. A-02 error
before/after a file's own COMMIT → nothing kept. A-03 kill between COMMIT and ledger → no double
apply. A-04 two concurrent runs (and via 6543 transaction pooler) → no double 0002. A-05 1-byte /
CRLF edit → refused. A-06 lower-version pending / duplicate prefix → refused. A-07 stray files
ignored/refused. A-08 ledger row with deleted file → refused/warned. A-09 ~/.psqlrc AUTOCOMMIT off →
no effect (-X). A-10 dry-run creates nothing (not even schema ops). A-11 long/locked migration →
bounded abort. A-12 ops schema not reachable via REST (Accept-Profile: ops, anon + user JWT) or SQL.
Baseline: A-13 ambiguous / no-match version → refused. A-14 ledger not empty → refused. A-15 empty
db → refused. A-16 baselining a file never run → marker / fingerprint check. A-17 piped confirmation
→ refused (/dev/tty only).
Production guard: A-18 target name spoofing. A-19 staging env pointing at production ref → refused.
A-20 env identity mismatch. A-21 wrong/empty/piped confirmation. A-22 staging missing/mismatch/
unreachable/paused → refused with reason. A-23 override needs a 2nd tty confirmation, loud, recorded.
Seed: A-24 user creation guarded before any account. A-25 guard bypasses (NULL email, no contact,
upper case, example.com.evil, sub.example.com, auth user without profile). A-26 seed on 0015 schema
complete, challenge totals 100. A-27 second run refused cleanly; production target refused.
A-28 no Kelvin data left on staging; signup race with 0002 owner email.
Backup/restore: A-29 only .enc (600, dir 700), no plaintext anywhere incl. on failure/Ctrl-C.
A-30 out-dir inside repo / worktree / symlink / .. / case variants refused; spaces quoted.
A-31 manifest counts from the dump's snapshot, exact count(*). A-32 real demo backup → PASS.
A-33 one table's DDL failing → FAIL; table sets compared. A-34 wrong passphrase ×1000 → all FAIL
(plaintext sha256 in manifest); truncated/tampered → FAIL. A-35 restore-check local socket only,
ignores PG* env, drops only its own db, also on Ctrl-C. A-36 Linux OpenSSL ↔ LibreSSL decrypt.
Secrets: A-37 special-character passwords; no `source`. A-38 no password in ps / bash -x / errors /
outputs. A-39 env file missing/644/missing key → clear error. A-40 git status clean; template has
placeholders only.
Workflow: A-41 none set → success + warning; partly set → fail. A-42 pg_dump 17 on runner (PGDG or
container), version mismatch fails; pooler host (no IPv6). A-43 schedule + workflow_dispatch only,
permissions read, concurrency, pinned actions, artifact = .enc + manifest, no derived unmasked
secret. A-44 YAML parsed with node; runner path simulated, not run.

Spec problems S1–S17 → v2 decisions (see CONTRACT.md "v2").

# BFT Coach Hub: lanes

Repo cloned 2026-11-14 into `app/` from `bangsarmanagement/bft-coach-hub` (branch `main`,
9 commits, last `c1dae4e` 26 Sep 2026 "Stage 2b"). Only `main` exists. All paths below are
relative to `app/`.

| Lane | What it is | Files | Code owner | Tests | Deploy |
|---|---|---|---|---|---|
| **app** | The screens: Next.js 15 App Router, React 19, Tailwind 4 | `src/app/**` (coach: `shifts/`, `checkin/`, `absences/`, `earnings/`, `pt/`, `account/`; manager: `manage/[studioId]/**`; owner/GM: `admin/**`), `src/components/`, `src/lib/` (`money.ts`, `time.ts`, `session.ts`, `people-actions.ts`, `supabase/{client,server,admin}.ts`), `src/middleware.ts` | `bft-builder` | `npm run build`, `npx eslint`, `npx tsc --noEmit`. **No JS unit tests yet** | Push to `main` deploys to production. Orchestrator only, Aaron's yes. PRs into `staging` once it exists |
| **db** | The database: timestamped SQL migrations run by hand in Supabase's SQL editor, RLS, ~45 `security definer` functions, view `extra_earnings` (security_invoker) | `supabase/migrations/2026092*_*.sql` (7 files, 0001–0007), `supabase/tests/*.sql` | `bft-db` | `cd supabase && ./tests/run.sh`: plain Postgres on socket `/tmp/pg:54329` with an `auth` stub (`tests/00_supabase_stub.sql`). Needs Postgres installed locally | SQL on production Supabase: Aaron's yes **and** Kelvin's. It is his database |
| **review** | Read everything, change nothing. The code audit | everything | nobody | `bft-checker`, six lenses | none |

Next migration number: `…000022` (0008–0021 are on crew branches, not yet in Kelvin's main). Never edit 0001–0007.

## Environments

| | URL | Supabase | Status |
|---|---|---|---|
| Production | bft-coach-hub.vercel.app | Kelvin's project, Singapore, Free plan | Live. Real coaches. **Never touched by the crew** |
| Demo (Aaron's) | localhost:3000 + sign-in page localhost:3001 | Aaron's free project `coach-hub-demo` (muczjyfeduajeupcbmfo), fake data | Running on this Mac; see `demo/README.md`. Not Kelvin's staging |
| Staging | (to create) | second project, fake data | Does not exist yet (needs Kelvin's invites) |
| Local DB tests | n/a | plain Postgres 17 on `/tmp/pg:54329` (Postgres.app) | Installed 20 Nov |

Env vars (`.env.example`): `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`,
`SUPABASE_SERVICE_ROLE_KEY` (server only, used in `src/lib/people-actions.ts`),
`NEXT_PUBLIC_SITE_URL`.

## Test kit (build once in the audit week, reuse after)

| Piece | Path | Status |
|---|---|---|
| Kelvin's SQL tests, Stage 1–2b | `app/supabase/tests/10…60_*.sql` | exist, not yet run by us |
| Seed data: every role, two studios, coach at both, Lead, 1 strike, cancelled class | `demo/seed.sql` (demo) and the fixtures inside `70_access_matrix.sql` | built 20 Nov |
| Role × table matrix (20 tables + view + RPCs) | `supabase/tests/70_access_matrix.sql` (branch crew/access-matrix) | built 20 Nov, reads only |
| Money golden file | `prep/golden-month-oct-2026.md` | drafted by hand, needs Kelvin's real rates |
| Frozen clock time tests | (to create) | not built |
| Phone check, 390 + 1440, no sideways scroll | (to create) | not built |

# Coach Hub: briefing for the incoming IT engineer

*Written 25 Nov 2026 for a technical reader. Aaron (who hired you) is not technical; the work
so far was done by Aaron with an AI coding assistant (Claude Code). Everything below is in this
folder, and the details are in the files named.*

---

## 1. What the project is

**The client:** a BFT (Body Fit Training) franchise operator in Malaysia, Studio 613 Sdn Bhd.
The owner (Kelvin) runs BFT Bangsar (live) and is opening Subang Jaya, with more studios planned.

**The app: Coach Hub.** A mobile web app (PWA) for running part-time coaches:
- coaches claim, drop and swap coaching positions in classes;
- they check in by scanning a QR code at the studio;
- managers verify attendance, handle no-shows, absences and strikes;
- Owner/GM/Finance manage pay rates, 8-Week-Challenge payouts and PT revenue splits;
- **Stage 3 (not built yet):** a monthly invoice per coach per studio, built from verified classes,
  plus bank details and a bank-transfer export.

**Kelvin built Stages 1 and 2 himself with an AI coding tool.** We were engaged to audit, harden,
finish Stage 2, build Stage 3 (pay) and take it live. The plan, phase by phase, is in
`PROJECT-PLAN.md`. His original build plan (with all business rules, pp. 3–5) is
`BFT-Coach-Hub-Build-Plan-2026-09-27.pdf`.

**It's his code and his data.** His GitHub repo, his Supabase, his Vercel, real coaches' personal
data (PDPA applies). We work on branches and pull requests that he reviews and merges.

---

## 2. Stack and environments

| | |
|---|---|
| Frontend | Next.js 15 (App Router), React 19, Tailwind 4, TypeScript |
| Backend | Supabase: Postgres with row-level security, ~45 `security definer` SQL functions, PostgREST |
| Hosting | Vercel; **every push to `main` deploys to production** |
| Repo | GitHub `bangsarmanagement/bft-coach-hub` (private, Kelvin's). Cloned locally in `app/` |
| Login | Email one-time code (Supabase Auth) |
| DB changes | Numbered SQL files in `supabase/migrations/`, historically pasted by hand into the Supabase SQL editor |

| Environment | Where | Status |
|---|---|---|
| **Production** | `bft-coach-hub.vercel.app` + Kelvin's Supabase (Free plan, Singapore) | Live, real coaches. **Never touched by us.** `main` is still at `c1dae4e` (26 Sep) |
| **Demo** | Aaron's own free Supabase project + the app run locally (`localhost:3000`, sign-in helper on `:3001`) | Fake data only; all our fixes were checked here. See `demo/README.md` |
| **Staging** | Not created yet | Needs Kelvin: a second Supabase project + Vercel preview settings (see fix #7) |
| **Local DB tests** | Postgres 17 (Postgres.app) on socket `/tmp/pg`, port 54329 | `cd app && supabase/tests/run.sh <dbname>` (test DB names must start `crew_`, `chk_` or `coachtest`) |

Maps of the code: `REPOS.md` (lanes, files, test kit, next migration number).

---

## 3. What has been done (as of 25 Nov 2026)

### Phase 1 — safety net
- Kelvin's own SQL tests had a fixed-date bug (failing since ~1 Oct) → fixed (`crew/test-dates`).
- A permanent role × table access test (`supabase/tests/70_access_matrix.sql`, ~1,100 checks).
- A demo copy with fake data so changes can be seen and tested.

### Phase 2 — the 13 audit findings
The audit is `prep/audit-report-2026-11-14.md`. Each fix has a contract (decisions, acceptance
tests, the checker's attack list) in `contracts/fix-N-*/`, tests that failed before the fix, an
adversarial review, and a check on the demo project.

| # | Finding (short) | DB migration | App change | Branch(es) | Pushed to GitHub? |
|---|---|---|---|---|---|
| 1 | Managers could read anyone's private details | 0008 | yes | `crew/fix-1-private-details`, `crew/fix-1-app-people` | yes |
| 2 | Every coach could read studio pay rates | 0009, 0010 | yes | `crew/fix-2-pay-rates`, `crew/fix-2-app-rates` | yes |
| 3 | QR check-in secret readable by every coach | 0011, 0012 | yes | `crew/fix-3-checkin`, `crew/fix-3-app-checkin` | yes |
| 4 | Verified classes not locked | 0013 | yes | `crew/fix-4-verified-lock`, `crew/fix-4-app-lock` | yes |
| 5 | Managers could put any coach in a Lead spot | 0014 | — | `crew/fix-5-lead-positions` | yes |
| 6 | Challenge shares could exceed 100% / overpay | 0015 | yes | `crew/fix-6-challenge-shares`, `crew/fix-6-app-shares` | yes |
| 7 | No staging, no backups | — (ops kit) | — | `crew/fix-7-staging-backups` (`ops/` folder) | yes |
| 8 | Late absence answers still removed the strike | 0016 | yes | `crew/fix-8-absence-deadline`, `crew/fix-8-app-absence` | **no, local only** |
| 9 | Strike window counted from marking, not class date | 0017 | yes | `crew/fix-9-strike-window`, `crew/fix-9-app-strike` | **no** |
| 10 | Correcting a no-show left the strike | 0018 | — | `crew/fix-10-noshow-correction` | **no** |
| 11 | Full-timers could drop/swap assigned classes | 0020 | yes | `crew/fix-11-fulltime-drop`, `crew/fix-11-app-drop` | **no** |
| 12 | Manager-coach can approve own PT at 100%; PT edits untracked | — | — | `crew/fix-12-*` branches created, **work not started** | no |
| 13 | Managers could edit classes directly (times, verify, delete) | 0019 | — | `crew/fix-13-class-edits` | **no** |

**Important about the branches:** the DB branches are **stacked** (each builds on the previous
one: fix-1 → 2 → 3 … → 13 → 11), and so are the app branches. Merge them in order. The
pull-request descriptions and **release order** (which migration runs before or after which app
deploy) are drafted in `prep/phase1-pull-requests.md` and in each fix's log entry in
`SESSION-LOG.md`. Example: 0009 → deploy the fix-2 app change → 0010; 0011 → app → 0012 → each
manager regenerates the QR code once.

**No pull requests are open yet**, and **no migration from us has been run on production.**

### The ops kit (fix #7, `ops/` on `crew/fix-7-staging-backups`)
- `ops/migrate.sh`: applies migrations in order with a ledger (`ops.schema_migrations`), one
  transaction per file, refuses edited/out-of-order files; production refuses unless staging has
  run the same files and you type the project ref. `--baseline`, `--up-to`, `--dry-run`.
- `ops/backup.sh` + `ops/restore-check.sh`: encrypted pg_dump and a restore check.
- `ops/seed/`: fake staging data with a guard against real people.
- Nightly backup GitHub Action (inactive until secrets are added).
- `ops/README.md` is the step-by-step for setting up staging and releasing.
- **Once the kit is set up, migrations should go through `ops/migrate.sh`, not the SQL editor.**

---

## 4. How the work has been run (you don't have to keep this, but it explains the files)

Each change was done by AI agents in separate git worktrees (`.crew-wt/`): a code owner writing
tests first, an adversarial checker trying to break it, and a fresh reviewer, for up to three
rounds, then a check on the demo project. Records:
- `SESSION-LOG.md` — newest first: what was done, verified, unverified, open, per session.
- `contracts/fix-N-*/CONTRACT.md` and `attack-list.md` — decisions and the attacks each fix survived.
- `supabase/tests/` on each branch — the SQL test files (90s = our fixes) plus scenario scripts.
- `app/src/lib/*.test.mjs` — Node tests for app logic (`node --test`).

---

## 5. What is blocked or open

**Waiting on Kelvin**
- Supabase **Pro** on production (backups, no pausing) — before any fix goes live.
- A **staging** Supabase project and Vercel settings: point **all** preview deployments at
  staging, not production (today previews of our pushed branches likely use production's
  variables), plus preview protection.
- Access for us (Supabase, Vercel) with least privilege.
- Reviewing and merging the pull requests in order; running migrations per the release order.
- **44 open questions** in `prep/access-questions-for-kelvin.md` and the **pay-rule questions
  Q-1–Q-9** in `prep/stage3-pay-spec.md` (Stage 3 can't be built without them).

**Still to do (our side)**
- Push branches for fixes #8–#11 and #13; open all pull requests (drafts exist).
- Fix #12 (PT self-approval and edit history).
- Finish Stage 2 end-to-end on a phone; then build **Stage 3 pay** against the hand-worked
  month in `prep/golden-month-oct-2026.md` (must match to the sen).
- Pilot with 3–5 coaches over one real month-end.

**Known risks / limits worth knowing**
- Release order matters for fixes #2, #3 and others; deploying the app before its migration (or
  the reverse) can break screens.
- Uploaded files (absence evidence in Supabase Storage) are in **no** backup.
- Production's state before our migrations is unverified (Kelvin pasted 0001–0007 by hand; the
  kit's `schema-diff.sh` compares production with staging after baselining).
- Anon/authenticated roles hold TRUNCATE by Supabase default; partly addressed in 0019.

---

## 6. Suggested first week

1. Read this file, `PROJECT-PLAN.md`, `prep/audit-report-2026-11-14.md`, then `SESSION-LOG.md`.
2. Get access from Kelvin (GitHub collaborator, Supabase/Vercel team member). Don't use anyone
   else's logins.
3. Run the local test suite on a branch (`supabase/tests/run.sh crew_test`) and the demo app.
4. Review the open branches; push the local-only ones and open the pull requests in order.
5. With Kelvin: Supabase Pro, create staging, follow `ops/README.md` step by step.
6. Agree the release plan with Kelvin, then Stage 2 completion and Stage 3.

**Ground rules we've kept:** never push to `main`; nothing on production without Kelvin's
written OK; fake data only outside production; secrets never committed (env files are git-ignored).

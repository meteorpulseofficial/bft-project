# BFT Coach Hub: session log

Every session ends with these four sections, newest first. An empty section says "none".

```
### <date>: <one-line title>

**Done & verified**: what, who proved it, how, when
**Done but unverified**: what, and what would confirm it
**Needs your approval**: ready, blocked on Aaron (or Kelvin), with the rollback
**Open**: found, not fixed, with the reproduction
```

---

## Logged live

### 2026-11-19: Coach Hub confirmed, deposit paid (Phase 0)

**Done & verified**
- Kelvin confirmed Coach Hub (RM5,000 build). 50% deposit paid (per Aaron, 19 Nov).
- Our GitHub account has **push** access to `bangsarmanagement/bft-coach-hub` (checked via
  API, 19 Nov). Only `main` exists, last push still 26 Sep (`c1dae4e`).
- Phase plan written: `PROJECT-PLAN.md`.

**Done but unverified**
- none

**Needs your approval**
- Send kick-off WhatsApp (`prep/kickoff-message.md`): Supabase Pro, Supabase + Vercel invites,
  branch protection on `main`, migrations 6–7 applied?, unpushed changes?
- One-page agreement not yet sent. Monthly support fee still to agree.

**Open**
- Push access means a mistaken push to `main` would deploy to live coaches. Until Kelvin adds
  branch protection, our rule stands: never push `main`, only `crew/*` branches + PRs.
- The marketing proposal PDF still says the RM25 bonus was "agreed for Coach Hub". Fix before
  sending.

### 2026-11-14: /crew review, code audit (checker only, no edits)

**Done & verified**
- Local Postgres 17 installed (Homebrew). Throwaway cluster on `/tmp/pg:54329`, fake data only.
- Kelvin's SQL tests: on the real repo, `50_claiming` fails since ~1 Oct because the tests use
  fixed dates. A date-shifted copy passes all 6 files (14 Nov). Test problem, not an app bug.
- `bft-checker` audit (02:04Z): **FAIL**, 7 blocks-deploy, 6 should-fix, 3 notes, plus a
  role × table matrix. The orchestrator independently reproduced F1 (manager reads anyone's
  contacts and notes via an inactive membership insert), F2 (coach reads rates), F3 (coach
  reads the QR check-in token), F4 (attendance changed after verify) and F5 (manager writes
  a non-Lead / other-studio coach into a Lead position), 14 Nov ~10:06 KL. Kelvin's phone and
  email in migration 0002 confirmed.
- Report for Kelvin: `prep/audit-report-2026-11-14.md`. Checker scripts kept in
  `audit-kit/` (build, seed, role matrix, probes, time edges). Reuse them as the test kit.

**Done but unverified**
- F6–F15 reproduced by the checker only (twice each), not re-run by the orchestrator.
- Anything needing the deployed stack: PostgREST column exposure, Auth invite flow,
  `absence-evidence` bucket policies, live DB time zone, real-phone QR and 390px layout.

**Needs your approval**
- Send the audit report to Kelvin (edit first; it describes weaknesses in his live app, so
  share it privately, not as a public link).
- Quote figures for Package A (staging + hardening) and Stage 3.

**Open**
- All 13 findings unfixed. No staging. Production migration state (0006–0007 applied?) unknown.

### 2026-11-14: Repo cloned, first look (read-only)

**Done & verified**
- Cloned `bangsarmanagement/bft-coach-hub` into `app/` (main, 9 commits, last 26 Sep).
- `next build`, eslint and `tsc --noEmit` all pass with dummy env vars (14 Nov).
- No secrets found in the git history. All 20 tables have RLS enabled; the one view
  (`extra_earnings`) is `security_invoker`. The service-role client is used only in server
  code (`src/lib/people-actions.ts`), never in a client component.
- REPOS.md filled with real paths.

**Done but unverified**
- Likely finding, not reproduced (no database yet): `studios_read` lets any member of a
  studio read the whole studio row, including `lead_rate` / `support_rate`. A coach could
  read default rates through the Supabase API, although no screen shows them. The plan says
  rates are Owner/GM/Finance only.
- Minor: `coach_reviews.review_date` defaults to `current_date`, which is the UTC date in
  Postgres, so a review entered before 8am KL is dated the day before.

**Needs your approval**
- Install Postgres locally (Homebrew) to run Kelvin's SQL tests and the audit's RLS tests.
- Ask Kelvin: are migrations 0006–0007 applied in production? (PDF said 1–5.) Any work
  since 26 Sep that is not pushed? OK to create a staging Supabase project?

**Open**
- No staging. No JS tests. Every push to `main` goes live.

### 2026-11-13: Pre-access prep (fallback plan, HANDOVER section 12)

**Done & verified**
- Stage 3 pay rules turned into numbered tests R-01…R-73, plus 9 open questions for
  Kelvin: `prep/stage3-pay-spec.md`. Written from the PDF only.
- One coach's October 2026 Bangsar invoice worked out by hand, total RM 2,805.33 with
  example rates: `prep/golden-month-oct-2026.md`. Arithmetic and calendar dates checked by
  script, 13 Nov.
- Mock-up of the coach invoice screen (390px) and the Finance month-end screen:
  `prep/invoice-mockup.html`. Rendered in the browser and checked, 13 Nov.
- Crew files created: `.claude/agents/bft-checker.md` (Bash/Read/Grep/Glob only),
  `bft-builder.md`, `bft-db.md`, `.claude/commands/crew.md`, `REPOS.md`,
  `CONTRACT-TEMPLATE.md`, this log.

**Done but unverified**
- `/crew` has not been run. It needs the cloned repo to do anything except review `prep/`.
- `REPOS.md` paths are guesses until the clone.

**Needs your approval**
- Decide whether to send Kelvin the open questions (Q-1…Q-9) before the meeting, or bring
  them to it.

**Open**
- Repo access not granted yet (requested 13 Nov).
- Real default Lead/Support rates unknown. The golden month uses RM60/RM45 as examples.
- Quote figures (day rate, RM per package) not set. Aaron's call.

# BFT Coach Hub — Handover

Written 2026-11-13 from the Hiiiilo session, after the demo call with Kelvin.
Open this folder as its own project. This is **not** part of Hiiiilo. Do not touch
`/Users/aaron/dev/Project Hiiiilo` from here.

## 0. Where we left off (read this first)

**Update 2026-11-13, first Coach Hub session:** repo access still not granted. Aaron chose
a **free** audit. Fallback done: `prep/stage3-pay-spec.md` (R-tests + Q-1…Q-9 for Kelvin),
`prep/golden-month-oct-2026.md` (hand-worked invoice, RM 2,805.33, example rates),
`prep/invoice-mockup.html`. Crew files built (`.claude/agents/bft-*`, `/crew`, `REPOS.md`,
`CONTRACT-TEMPLATE.md`, `SESSION-LOG.md`). Next: on access, clone → fill REPOS.md paths →
staging → `/crew review`. See `SESSION-LOG.md`.

Last updated 2026-11-13, end of the Hiiiilo session.

**Status**
- Demo call with Kelvin done (13 Nov, 7:20pm). He agreed to a Hiiiilo pilot for the Subang
  campaign (that stays in the Hiiiilo project) and asked us to quote for finishing Coach Hub.
- Aaron told Kelvin on WhatsApp he would update him after a team meeting (~14 Nov).
- **Aaron is now asking Kelvin for read access** to `bangsarmanagement/bft-coach-hub` on
  GitHub. Not granted yet as of this writing.
- No quote given. Nothing built. No code seen yet.

**Decided in this session**
- Coach Hub is a separate project from Hiiiilo (section 4).
- **Do not rebuild the app to win the deal.** He already built Stage 1 and most of Stage 2.
  Win it with an audit of his code plus one working slice of Stage 3 pay (section 12).
- Work runs as a crew, using Hiiiilo's /fixcrew **v2** rules (sections 10 and 11).

**Next session, in order**
1. Ask Aaron: has Kelvin given repo access yet? Which GitHub account was added?
2. **If yes:** clone the repo into this folder (`/Users/aaron/dev/bft-coach-hub/app/` or
   similar), build the crew (section 10, with section 11 rules), then run the pre-meeting
   plan in section 12, Option C.
3. **If not yet:** do the fallback in section 12 (hand-worked invoice + screen mock-up from
   the PDF) so Aaron has something for the meeting either way. Set up the crew files that
   do not depend on the code (agents, command, session log, contract template).
4. Time box: 1–2 days of unpaid work, total. Meeting 3–5 days after the access request.


Source document: `BFT-Coach-Hub-Build-Plan-2026-09-27.pdf` (in this folder). Kelvin sent it
on WhatsApp after the call with "This is my progress" and "It will be great if your team can
quote me how much to complete it and test it for us and later deploy."

---

## 1. Who Kelvin is

- **Kelvin Liu.** Runs a **BFT** (Body Fit Training) franchise in Malaysia.
- Company: **Studio 613 Sdn Bhd**, Co. Reg. 202401039157, 8A Jalan Vivekananda, Brickfields,
  50470 KL. It owns every studio.
- Studios: **BFT Bangsar** (live), **BFT Subang Jaya** (pre-sales campaign coming).
  Plans **4 locations by 2027**.
- WhatsApp: 60124380103. App owner login: kcl211@gmail.com.
- He vibe-codes. He built Stage 1 of this app himself, with an AI coding tool (the PDF
  reads like an AI-written build plan addressed to him: "@Kelvin", "your lawyer").
- He and Aaron got on well on the call: Aaron's follow-up said they had "similar topics to
  talk about" (business and vibe coding) and "let's discuss more on the opportunities to
  work together." Kelvin said yes.

## 2. What we discussed on the call (13 Nov 2026, 7:20pm)

From the Gemini notes and the WhatsApp thread.

**Hiiiilo side (stays in the Hiiiilo project):**
- He uses Lulu chat today (button menus). Gets 10–20 leads a day.
- Lost a WhatsApp number to a ban 3–4 months ago. Worried about bans.
- Subang pre-sales campaign: target ~2,000 leads, ~10% conversion.
- Quoted: RM1,599 setup (money-back guarantee) + RM599/month.
- **Agreed:** run the Subang campaign through Hiiiilo as a pilot.
- His next steps: check if the BFT global app has an API; get a new number.
- Our next step: warm up his new number.
- Blocker: BFT class booking runs on a franchise-wide app (Glofox, owned by ABC Fitness).
  API access is unsure.

So he has **not** said no to Hiiiilo. Hiiiilo is the lead/sales side; Coach Hub is a
second, separate opportunity.

**Coach Hub side (this project):**
- He is building an internal system for part-time coach scheduling and pay slips.
- Aaron said he is open to a partnership on custom software builds.
- After the call he sent the plan and asked for a quote to **complete, test and deploy**.
- Aaron replied that he would discuss with the team and update him after (due ~14 Nov).

## 3. What the app is

A mobile web app (PWA) for BFT studios. Part-time coaches claim coaching positions in
classes, check in by QR, and get a monthly invoice generated for them. Managers verify
attendance and handle absences. Owner, GM and Finance manage rates and pay.

**Stack (his choices, already live):**
- Next.js on Vercel, Supabase (Postgres, Singapore, row-level security), GitHub private repo
  `bangsarmanagement/bft-coach-hub`, every push to `main` deploys.
- Login by email code, sent through a Gmail account over SMTP.
- DB changes are numbered SQL files run by hand in Supabase (1–5 applied as of 27 Sep).
- Live at `bft-coach-hub.vercel.app`.

**Roles:** part-time coach, full-time coach, studio manager, GM, owner, finance.
One login per person, roles per studio.

**Where it stands (as of the PDF, 27 Sep 2026 — may have moved since):**

| Stage | What | Status |
|---|---|---|
| 1. Foundation | Logins, roles, studios, timetable, 12 class names, people | Done |
| Extras | 8 Week Challenge payouts, PT split, coach reviews, GM access | Done |
| 2. Coach loop | Claim / drop / swap, QR check-in (180-min runs), reminders, verify, absences + strikes, late report, cancel class | Built, in testing |
| 3. Pay | Coach rates, late-pay review, monthly invoice per coach per studio (PDF), bank details with approval, bank export, audit log | Not started |
| 4. Pilot + integrations | Pilot 3–5 coaches for 2–3 weeks, WhatsApp reminders (Meta Cloud API), Glofox sync, dashboard | Not started |

Business rules are detailed in the PDF, pages 3–5. Key ones:
- Free drop until 24h before class; inside 24h, swap only.
- Call time 30 min before class; check-in opens 60 min before.
- One QR scan covers classes that start within 180 min of the previous one ending.
- No-show → explain within 5 days. Not valid = no pay + 1 strike. 2 strikes in 90 days
  pauses booking.
- Pay rate: coach rate → special event rate → studio default Lead/Support rate.
- Pay for a class is frozen on the invoice line when the class is verified.
- One invoice per coach per studio per month, all billed to Studio 613.

**Still open on his side (from the PDF checklist):**
- Subang Jaya timetable; Stage 2 decisions (late grace, cancellation notice).
- For Stage 3: superstar coach rates, month-end cut-off and pay date, which bank (for the
  bulk-transfer file), accountant's view on **LHDN e-invoicing and PERKESO** for part-time
  coaches, lawyer's OK on PDPA consent wording.
- In parallel: BFT HQ approval for branding, domain + Resend email, Meta Business
  verification + WhatsApp number, Glofox API access, Supabase Pro + Vercel paid plan,
  revoke the GitHub token after the build.

## 4. Why this is a separate project

- **Different product.** Hiiiilo is an AI WhatsApp sales agent. Coach Hub is internal staff
  scheduling, attendance and payroll. No shared feature today.
- **Different stack.** Hiiiilo is n8n + Firestore + a single-file dashboard. Coach Hub is
  Next.js + Supabase + Postgres. No shared code.
- **Different owner.** Kelvin owns the repo, the Supabase and Vercel accounts and the data.
  This is client work on his codebase, not a Hiiiilo tenant.
- **Different money model.** Hiiiilo is a subscription. This is a build fee plus maybe a
  retainer or partnership.

The only possible overlap later: Stage 4 WhatsApp reminders. Keep that inside Coach Hub on
the Meta Cloud API as he planned. Do not route it through Hiiiilo's WhatsApp.

## 5. Read on Kelvin

- He is a builder-owner, not a passive buyer. He already made most product decisions and
  wrote them down well. He wants a team to **finish and harden** it, not to redesign it.
- He is tech-curious (asked which LLM we use, how multi-bubble replies work). He will judge
  us on how we talk about the code.
- He is cost-aware (compared Lulu's RM299 AI add-on, asked about SleekFlow).
- He is growing (4 studios by 2027). A clean, multi-studio app matters to him.
- Two things he cares about across both projects: not losing leads, and paying coaches
  correctly.

## 6. Plan

### Step 0 — Before quoting (this week)
1. Ask Kelvin for **read access** to the GitHub repo and a **test login** for each role on
   a non-production copy. Do not quote a fixed price before seeing the code.
2. Ask what has changed since 27 Sep (is Stage 2 finished? still in testing?).
3. Ask: who builds today — him alone with an AI tool, or a freelancer too?

### Step 1 — Code audit (paid or free, Aaron's call)
Half a day to two days. Check:
- Does it build and run locally? Are migrations in the repo and in order?
- Row-level security on every table, really (rates and bank details only visible to
  Owner/GM/Finance; a coach sees only their own rate).
- Are there tests? Is there a staging environment, or does every push go live to coaches?
- Secrets: Gmail SMTP password, Supabase service key, the GitHub token mentioned in the PDF.
- Money logic: rate selection, frozen invoice lines, challenge and PT splits.
Output: a short report to Kelvin + a firm quote.

### Step 2 — Quote structure (suggested)
Fixed price per stage, each ending in something he can test on his phone (same as his plan):

| Package | Scope | Rough effort |
|---|---|---|
| A. Audit + hardening | Section above, plus staging env, tests on money logic | 3–5 days |
| B. Finish Stage 2 | Fix and test coach loop end to end | 1–2 weeks |
| C. Stage 3 Pay | Rates, late review, invoices (PDF), bank details + approval, bank file, audit log | 2–3 weeks |
| D. Stage 4 | Pilot support, WhatsApp reminders, dashboard. Glofox only if API approved | 1–2 weeks + waiting on third parties |
| E. After launch | Monthly retainer: hosting watch, fixes, small changes | monthly |

Effort numbers are guesses before seeing the code. Aaron sets the day rate and the RM
figures. Glofox and WhatsApp depend on ABC Fitness and Meta — price them separately and
say so, so a third-party delay is not our delay.

### Step 3 — Partnership option (bigger idea)
BFT has many franchisees. Every one of them has the same part-time coach problem. Options
to raise with Kelvin:
- **Build for a lower fee in exchange for the right to resell** Coach Hub to other BFT
  franchisees (or other boutique fitness studios), with a revenue share to Kelvin.
- Or **co-own** it as a product: he brings the domain knowledge and the first customer,
  we bring build, hosting and support.
- Needs: written agreement on IP, who owns the code and data, BFT HQ's view on branding
  (the app uses BFT logos "subject to HQ approval" — a resold version would need to be
  unbranded or HQ-approved).
Raise this only after the audit, once we know the code is worth building on.

## 7. Risks to say out loud

- **Payroll is money.** A wrong rate or a missed class is a real coach paid wrong. Insist on
  tests and a pilot month run alongside the current method.
- **Inherited AI-written code.** Could be fine, could need rework. Audit first.
- **LHDN e-invoicing / PERKESO.** Legal and tax questions. Kelvin's accountant decides; we
  build what they say. Do not give tax advice.
- **PDPA.** Data in Singapore with consent. Kelvin's lawyer approves the wording.
- **Glofox API** may never be approved. The weekly template must keep working without it.
- **Free tiers.** Supabase Free pauses and has no backups. Move to Pro before real coaches.
- **Every push to `main` deploys to production.** Set up a staging branch before we touch it.

## 8. First message to Kelvin (draft, Aaron to edit and send)

> Hi Kelvin, went through the build plan with the team. Really solid work, the rules are
> clear and the stages make sense. Before we give you a number, we'd like to look at the
> code so the quote is real and not a guess. Can you add us to the GitHub repo (read only is
> fine) and give us a test login for each role? Also, has anything changed since the 27 Sep
> version, is Stage 2 done? We'll come back with a short review and a fixed quote per stage.

## 9. Open questions for Aaron

- Free audit (to win it) or paid audit?
- Day rate / pricing model for client builds?
- Partnership: interested in reselling to other BFT franchisees, or keep it as a one-off build?
- Who on the team does the build?

---

## 10. Build the crew first (same model as Hiiiilo's /fixcrew)

Aaron runs Hiiiilo work as a crew, and wants the same here. Before any coding on Coach
Hub, set this up in this folder. **The crew is the rule set, not the headcount**: one agent
writes, a different agent tries to break it, and the main session routes between them and
holds the only deploy step.

### 10.1 Read the Hiiiilo version first (read only, never edit it)

These files were upgraded to **v2** on 13 Nov (attack list first, tests fail first, checker
and code review in parallel, contracts frozen on approval, own worktree for the UI owner).
So section 11 is already built into them: copy the v2 shape directly. The v1 copies sit in
`/Users/aaron/dev/Project Hiiiilo/.claude/backup-fixcrew-v1-20261113/` — ignore those.

| File | What to take from it |
|---|---|
| `/Users/aaron/dev/Project Hiiiilo/.claude/commands/fixcrew.md` | The orchestrator's steps: lane + mode menu, pre-flight, spec gate, spawn, loop, ship, session log |
| `/Users/aaron/dev/Project Hiiiilo/.claude/agents/hiiiilo-checker.md` | The checker: no Edit/Write tools, make the test fail on old code first, report format, PASS / FAIL / CANNOT VERIFY |
| `/Users/aaron/dev/Project Hiiiilo/.claude/agents/hiiiilo-fixer.md` | A code owner: owns named files only, never checks its own work, never deploys, handover format |
| `/Users/aaron/dev/Project Hiiiilo/.claude/agents/hiiiilo-ui.md` | A second code owner for the UI lane |
| `/Users/aaron/dev/Project Hiiiilo/REPOS.md` | The lane table the menu is built from |
| `/Users/aaron/dev/Project Hiiiilo/hiiiilo-ops/CONTRACT-TEMPLATE.md` | The file handoff for features that cross two lanes |
| `/Users/aaron/dev/Project Hiiiilo/.claude/workflows/checker-sweep.js` | The wide sweep: one finder per failure lens, two refuters per finding |

Copy the **structure and the rules**. Do **not** copy the Hiiiilo-specific gotchas
(Firestore, n8n, tenants, WhatsApp, `index.html`). Those are Hiiiilo's bug history; Coach
Hub needs its own, listed in 10.3.

### 10.2 The rules that carry over unchanged

- **Owner never checks, checker never fixes.** The checker has Bash, Read, Grep, Glob only.
- **Nobody says "fixed" or "should work".** Code owners say what they changed and claim;
  the checker decides with evidence and a timestamp.
- **Checker makes its test fail on the old code first.** A test that passes on both proves
  nothing.
- **Agents do not talk to each other.** Every finding goes through the orchestrator,
  verbatim. Three rounds on the same bug: stop and bring it to Aaron.
- **One lane per session.** Each code owner is told exactly which files it owns.
- **Features get a spec Aaron approves before code. Deploys get a second yes.** An agent
  saying "ready" is not approval.
- **Cross-lane features hand off through a file** (`CONTRACT.md` + `fixture.json` with the
  field present, absent and malformed), written and approved before either lane codes.
- **Every session ends with four sections**, in `SESSION-LOG.md` and in the chat:
  Done & verified / Done but unverified / Needs your approval / Open. Empty = "none".
- **Git:** never `git add -A`; commit your own hunk only.

### 10.3 Coach Hub lanes and agents

Fill in exact folder paths after the repo is cloned. The app is Next.js + Supabase, so the
split is UI/server code vs database:

| Lane | Files (confirm after clone) | Code owner | Tests | Deploy |
|---|---|---|---|---|
| **app** | Next.js pages, components, server actions / API routes | `bft-builder` | `npm run build`, lint, unit tests, render at 390 and 1440 | Push to `main` deploys to production. Orchestrator only, Aaron's yes |
| **db** | `supabase/` SQL migrations (numbered files), RLS policies, views like `extra_earnings` | `bft-db` | Run migrations on a local or staging Supabase; RLS tests per role | SQL run on production Supabase. Orchestrator only, Aaron's yes (and Kelvin's, it is his database) |
| **review** | everything, read only | nobody edits | `bft-checker` | none |

Agents to create in `.claude/agents/`:

- **`bft-builder.md`** — owns the app lane files named per session. Never touches SQL
  migrations, never pushes, never runs SQL on production.
- **`bft-db.md`** — owns migrations and RLS. Every new table gets RLS in the same
  migration. Never edits app code, never runs anything on production.
- **`bft-checker.md`** — tools Bash, Read, Grep, Glob only. Its failure lenses for this app:
  1. **Data leaks across roles.** Log in as each of the six roles. A coach must never see
     another coach's rate, invoice, bank details or private notes. A studio manager sees
     only their own studio. Test against the database with RLS on, not just the UI.
  2. **Money.** Rate order (coach rate → special event rate → studio default), Lead coach
     on a Support position, frozen invoice lines (a later rate change must not alter a past
     invoice), challenge % and PT % splits, rounding to sen, cancelled class = no pay,
     late items blocking invoice approval.
  3. **Time.** Kuala Lumpur time vs UTC on Vercel and in Postgres. The 24h drop line, call
     time (30 min before), check-in window (60 min before), the 180-min QR run, 5-day
     absence window, 2 strikes in 90 days, month-end cut-off. Classes near midnight and on
     the last day of the month.
  4. **Multi-studio.** Adding a new studio in Settings must work with no code change.
     Studio rules override the group default. One coach at two studios gets two invoices.
  5. **Mobile.** It is a phone app for coaches. 390px first, no sideways scroll, QR scan
     works on a real phone camera.
  6. **Secrets and PDPA.** No keys in the repo or the client bundle. Bank details
     encrypted and readable only by Owner and Finance.
- **Checker data rule (different from Hiiiilo):** this database holds real coaches'
  personal and bank details, and it belongs to Kelvin. The checker works on a **staging
  copy with fake data**, never reads production rows, never writes anywhere.

Also create:

- **`.claude/commands/crew.md`** — the orchestrator command, adapted from `fixcrew.md`.
  Asks lane (app / db / review) and mode (bug / feature / review) with a menu, never
  guesses.
- **`REPOS.md`** — the lane table above, with real paths.
- **`CONTRACT-TEMPLATE.md`** — for features touching both lanes (most Stage 3 pay work:
  a table in `db`, a screen in `app`).
- **`SESSION-LOG.md`** — empty, with the four-section format at the top.
- Optional later: a `checker-sweep` workflow with the six lenses above, before each
  production deploy.

### 10.4 Before the crew can run

- **Staging first.** Today every push to `main` goes straight to the coaches. Set up a
  `staging` branch with a Vercel preview and a second Supabase project with fake data.
  The crew works there; production deploys only after the checker passes and Aaron says yes.
- **Repo access.** We need Kelvin to add us to `bangsarmanagement/bft-coach-hub`. Agree with
  him whether we push to branches and open PRs he merges, or push to `main` ourselves.
  Default to PRs: it is his code.
- **The first crew run is review mode.** The code audit in section 6, Step 1, is exactly
  that: `bft-checker` alone, all six lenses, no edits. Its report becomes the quote.

### 10.5 Done when

- `/crew` in this project shows the lane menu and spawns an owner + checker.
- The checker's definition has no Edit or Write tool.
- `REPOS.md` has real paths from the cloned repo.
- One review-mode run has written its four sections to `SESSION-LOG.md`.

---

## 11. Crew v2 — fixes for where the Hiiiilo crew lost time

Measured from Hiiiilo's `SESSION-LOG.md` (12–13 Nov, the first two days of /fixcrew). The
crew works, but five patterns cost most of the rounds. Build the BFT crew with these fixes
from day one.

| What slowed Hiiiilo | Evidence | Fix for BFT |
|---|---|---|
| **Bugs found one per round** | `class` booking: 5 checker rounds, each FAIL a *different* bug. Code review then found 3 more after the PASS | Checker writes its full attack list **before** code and gives it to the builder (11.1 step 2). Every round re-runs the whole list, not just the last finding. Code review runs **at the same time** as the checker, not after |
| **Shape changed mid-build** | Business knowledge contract went v1 → v20 in about a day. The UI lane rebuilt against v9, v11 and v18; one session lost track at v12 | No lane codes until the contract is reviewed by the checker **and** approved. Questions go into the contract before it is frozen. After freezing, a change needs Aaron's yes |
| **Big issues found late** | The wide sweep ran just before deploy and found 11–43 findings each time | Run the checker on the **plan** first. The one Hiiiilo plan review (12 Nov) caught 8 problems, including understated cost, before any code |
| **Test tools built per bug** | Replay harnesses and scanners were written or rewritten inside individual fixes | Build the test kit once, in the audit week (11.2). Every later round reuses it |
| **Sessions stepping on each other** | A commit-scope FAIL: a patch carried another session's hunk; three sessions shared one `index.html` | Every session works in its **own git worktree and branch**. One PR per change. This is a normal repo, so the Hiiiilo collision problem need not exist here |

### 11.1 The improved loop (replaces the order in fixcrew step 4–5)

1. **Spec from the rules.** Kelvin's PDF already lists the business rules (pages 3–5).
   For each stage, turn every rule into a numbered acceptance test before any code:
   "R-12: a coach drops 23h59m before class → refused, swap offered." This list is the spec.
2. **Pre-mortem.** The checker reads the spec and writes its attack list: every input that
   could break it, using the six lenses in 10.3. Aaron approves spec + attack list together,
   in one question.
3. **Tests first.** The builder writes the acceptance tests and the attack tests, and shows
   they **fail** on the current code. Then writes the code until they pass.
4. **Check in parallel.** The checker and a code reviewer run at the same time on the same
   diff. Their findings go back to the builder together, in one message.
5. **Full re-run every round.** All tests, not just the new one. A fix that breaks an earlier
   rule is caught the same round.
6. **Three rounds, then stop** (unchanged). Bring the trail to Aaron.
7. **Ship** as before: Aaron's yes, deploy, verify on the real URL, four-section log.

### 11.2 Build the test kit once (in the audit week)

The first crew run (review mode, the code audit) also builds these. Every later session
reuses them, so a check takes minutes, not a new script:

- **Seed data:** a staging database with fake coaches covering every role, two studios with
  different rules, a coach at both studios, a Lead coach, a coach with 1 strike, a month
  with a public holiday and a cancelled class.
- **Role test:** sign in as each of the six roles and try to read every table. Expected
  result is a fixed table (role × table → allowed / denied). Any change to it fails the test.
- **Money golden file:** a fixed month of classes, check-ins, challenges and PT sessions,
  with the correct invoice for every coach worked out by hand once and checked with Kelvin.
  Every pay change must reproduce it to the sen.
- **Frozen clock:** all time rules tested at fixed KL times, including 23:59, month end, and
  the 180-min QR edge (179, 180, 181 minutes).
- **Phone check:** a script that renders key screens at 390 and 1440 and fails on sideways
  scroll.

### 11.3 Run lanes in parallel, safely

- Each stage splits into a `db` half and an `app` half. Once the contract is frozen, both
  halves run **at the same time** in separate sessions and worktrees. The app half builds
  against the contract's fixture, then one session runs the integration check.
- Stage 3 (pay) has independent pieces: invoice PDF, bank file export, late-pay review,
  bank-detail approval. After the shared tables land, these can be separate sessions.
- Do not run two sessions on the same files. Parallel only across different files.

### 11.4 What this will and will not do

- It cuts the number of rounds (most bugs are found before code, not one per round) and it
  removes waiting between lanes.
- It cannot promise zero bugs. It finds the bugs we thought to look for. The pilot month
  (Stage 4: 3–5 coaches, 2–3 weeks, run alongside the current way of paying) is still the
  real test of pay.
- More agents is not faster. Each extra agent costs tokens and a handoff. Use the six
  lenses as one checker, and the wide sweep only before a production deploy.


---

## 12. Pre-meeting plan: how to win the build

Aaron asked whether to build the app and show it to Kelvin. **Decision: no.** Build a small
piece that proves we can finish **his** app, better than he can alone with an AI tool.

**Why not rebuild:** weeks unpaid; it copies Stage 1, which already works; it competes with
his own work (he sent it as "This is my progress"); it would be built from the PDF, not his
code; and if he signs, we work in his repo anyway.

**Why not quote only:** our real competitor is Kelvin plus his AI coding tool. A number
alone gives him no reason to pay us. And quoting unseen code is a guess.

### Option C (chosen) — audit + one slice, 1–2 days max

Bring two things to the meeting:

1. **A one-page audit of his code.** Run the crew in review mode (checker only, no edits)
   with the six lenses in 10.3. Look for: a coach able to read another coach's rate or bank
   details (RLS), secrets in the repo or client bundle, Supabase Free (no backups, pauses),
   every push to `main` going live with no staging, no tests on money or time rules, KL vs
   UTC time handling. Only real findings, each reproduced. Plain words, no jargon — Kelvin
   reads it, and it must not read as "your code is bad". Frame it as "what to harden before
   coaches are paid from this".
2. **One working slice of Stage 3 (pay), on a branch, never `main`.** Suggested: one coach's
   monthly invoice for BFT Bangsar from verified classes + challenge payout + approved PT,
   with the rate order from the PDF (coach rate → special event rate → studio default),
   frozen invoice lines, and tests that prove the total to the sen. Use fake coaches on a
   staging copy, never his real data. This is the hardest part and the part he has not
   started.

Then the quote: fixed price per stage (section 6, Step 2), with the audit findings as the
first package.

### Fallback — no repo access before the meeting (half a day)

- Work out one coach's invoice **by hand** from the PDF: the Bangsar timetable (page 10),
  default 1 Lead + 1 Support, 50% challenge share, 50/50 PT, a late arrival, a no-show, a
  cancelled class. Show every line and the total.
- A simple mock-up of the coach's invoice screen and the Finance month-end screen.
- The line for Aaron: "With repo access, we turn this into tested code in X days."
- Rates are not in the PDF (only "default rates" set on the Studios page). Use clearly
  labelled example rates, or ask Kelvin for them.

### What to pitch

- Not "we write code" — he can already generate code. Pitch **the crew**: one AI writes,
  a separate AI tries to break it, every pay change is checked against a hand-worked month
  before it ships. For an app that pays people, that is the product.
- Do not go quiet. Send the access request now (done), meet 3–5 days later.

### Cons to accept

- Depends on Kelvin granting access quickly.
- Still 1–2 days unpaid.
- He could fix the audit findings himself. Fine — it earns trust, and Stage 3 is still ours
  to sell.

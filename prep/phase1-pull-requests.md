# Phase 1 pull requests: ready to push (drafts)

Built and checked on 20 Nov 2026. **Committed on this Mac only. Not pushed to Kelvin's
GitHub yet** (Aaron to OK). Neither change touches the app or the database: only test files.

> **Update 22 Nov (fix #7, PR 14): how database changes are run.** Once the `ops/` kit (PR 14) is
> merged and set up, every "Kelvin runs **00XX** in the SQL editor" below means:
> `ops/migrate.sh staging --up-to <00XX version>`, check staging, then
> `ops/migrate.sh production --up-to <00XX version>` — at the point in the release order that
> section names (before or after its app change). Don't paste them in the SQL editor any more:
> the kit keeps a record of what ran, and a hand-pasted file would be missing from it. If any of
> 0008+ were already pasted before the kit is set up, tell us: production is then baselined to that
> version (`ops/README.md`). The result line each migration prints shows as a `NOTICE:` line.

| PR | Branch | Commit | What |
|---|---|---|---|
| 1 | `crew/test-dates` | `b59ca81` | Fix Kelvin's tests that broke when 28 Sep passed |
| 2 | `crew/access-matrix` | `caea2a5` (on top of 1) | Permanent "who can read what" test |

PR 2 sits on top of PR 1, so open PR 1 first, then PR 2 against `crew/test-dates` (or against
`main` after PR 1 is merged).

**Before pushing, check:** has Kelvin turned on branch protection for `main` (kick-off message
point 4)? Either way we only push `crew/*` branches, never `main`. Vercel may build a preview
for a pushed branch. That's harmless here, because the app code is unchanged.

Commands (after Aaron's OK):

```bash
cd "/Users/aaron/Documents/BFT Project/app" && git push -u origin crew/test-dates crew/access-matrix
```

---

## PR 1: Tests: use a test week relative to today instead of 28 Sep

**Base:** `main` · **Branch:** `crew/test-dates`

### Why
The database tests created classes for the fixed week of 28 Sep 2026. Since early October
`50_claiming` fails ("This position no longer exists"), because it looks for classes more
than 3 days ahead and there are none. Our review also found that the time-zone check could
not catch a time-zone bug on a machine set to Malaysia time, and that `60_stage2b` failed
every night between about 10:25 and 11:40pm.

### What changed (tests only, no app or database changes)
- **10_stage1:** the test week is always 4–10 days ahead, worked out from today's Kuala
  Lumpur date. The check "Monday 06:00 KL is stored as Sunday 22:00 UTC" now fails if the
  time-zone conversion is ever removed, on any machine.
- **50_claiming:** checks it has the classes it needs, and each refusal must give its exact
  message (e.g. "Lead positions need Lead status at this studio."), so a test can't pass for
  the wrong reason.
- **60_stage2b:** the two back-to-back test classes always fall on the same local day, so the
  late-evening failure is gone. Nothing it asserts changed.
- **run.sh:** `tests/run.sh [database]` (only test names allowed: `coachtest`, `crew_*`,
  `chk_*`), uses UTC like Supabase, runs from any folder.
- **20:** comment only.

### How it was checked
- Full suite passes. Also checked at simulated times: every hour of a week, every minute
  around midnight, month ends, 31 Dec, 28/29 Feb, under UTC, Malaysia, +14 and −11 time zones.
- Deliberately broken versions of the app's functions (no time-zone conversion, missing
  refusal) now make the tests fail; on `main` they passed.
- A separate checker tried to break it (PASS), plus an independent code review (nothing
  blocking).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR 2: Tests: permanent who-can-read-what check

**Base:** `crew/test-dates` (or `main` after PR 1) · **Branch:** `crew/access-matrix`

### Why
Coach Hub holds coaches' phone numbers, addresses, pay rates and soon bank details. Before
fixing anything or building pay, we want an automatic check that says exactly who can read
what, so any change that leaks data fails straight away.

### What it does
- New file `supabase/tests/70_access_matrix.sql`, run last by `run.sh`.
- 18 kinds of user: signed out, owner, GM, finance, both studio managers, each kind of
  coach, plus people who are inactive or removed. 1098 checks, covering every table, the
  earnings view, and 40 sensitive columns.
- Uses its own fake data and undoes everything at the end. It refuses to run on anything but
  a test database.
- **Known problems from our 14 Nov review are recorded by number**: #1 (managers reading an
  inactive member's details), #2 (coaches and managers reading pay rates), #3 (coaches
  reading the QR check-in code). The test tells us the moment one is fixed or gets worse.
- **Questions your plan doesn't settle** (e.g. should Finance see pay rates?) are recorded as
  how the app behaves today, marked "pending Kelvin". We'll send the list separately.
- Any new table or column without a "who can see this" entry fails, so the Stage 3 pay
  tables have to declare who can see them.

### How it was checked
- Passes alone and after the full suite, in UTC and Malaysia time, run twice; the database is
  identical before and after.
- Dozens of deliberately broken access rules (rates readable by everyone, a studio swap,
  security switched off on a table, an inactive manager keeping access, a new bank-account
  column) each make it fail and name the exact problem.
- Three rounds with a separate checker (final: PASS) and an independent code review (final:
  nothing blocking).

### Not in this PR
Write access (who can add, change or delete what) comes next, together with the fixes in
Phase 2.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

# Phase 2 pull requests (drafts, 20 Nov 2026)

| PR | Branch | Commit | What |
|---|---|---|---|
| 3 | `crew/fix-1-private-details` | `21fc26f` (on top of PR 2) | Audit #1, database half: migration 0008 + tests |
| 4 | `crew/fix-1-app-people` | `de28999` (on top of PR 2) | Audit #1, app half: "Add coach" / person page rules |

Ship PR 3 and PR 4 together: the database half alone still leaves the app's own "Add coach"
route open. **0008 must be run in Supabase's SQL editor by Kelvin** (or by us with his written
OK) after PR 4 is deployed. Rollback: PR 4 is a normal revert; 0008 can be undone by re-running
the original policy/function definitions from migrations 0001, 0003 and 0007 (we will supply
the exact SQL with the PR).

Push command (after Aaron's OK and Kelvin's write access):

```bash
cd "/Users/aaron/Documents/BFT Project/app" && git push -u origin crew/fix-1-private-details crew/fix-1-app-people
```

## PR 3: Fix: managers could read anyone's private details (database)

### Why
Our 14 Nov review (finding #1): a studio manager could read and change the phone number,
address and private notes of anyone in the company, including you and Finance, by quietly adding
them to their studio through the database and removing them again. We reproduced it on a copy
with fake data, including on a real hosted Supabase project.

### What changed (new migration 0008; your files 0001–0007 untouched)
- Managers can no longer add or delete studio memberships directly; adding a coach still works
  through the app. Owner/GM unchanged.
- When editing a membership, managers can change only Lead status and active/inactive, not on
  their own record and not on Owner/GM/Finance records.
- Managers no longer see a former (inactive) coach's phone, address and notes. Owner/GM still do.
- "Resume booking" can't be used by a manager on themselves, on Owner/GM/Finance, or on someone
  with no coach record at that studio (it could previously notify anyone).
- Only Owner/GM can change a person's contact email.

### How it was checked
- New test file `80_fix1_private_details.sql` (132 checks) fails on the old code (60 failures)
  and passes now; the who-sees-what matrix (1,098 checks) changes only in the #1 cells.
- Full suite passes in UTC and Malaysia time; nine deliberately weakened versions of the fix
  are each caught. An adversarial checker passed it after three rounds, plus an independent review.
- Applied to our demo Supabase project: the original attack is refused at every step, while
  setting Lead, deactivating and editing a coach's phone still work.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

## PR 4: Fix: "Add coach" could attach anyone in the company (app)

### Why
The app's add-person action uses the server key, which skips database rules. A manager typing
your email (or another studio's coach's) into "Add coach" got the same access as finding #1.

### What changed
- A manager can add an existing person only if they already coach at one of the manager's
  studios. Owner/GM/Finance, people from other studios, and the manager themselves get a clear
  "ask the Owner or GM" message. New coaches by invite: unchanged. Owner/GM: unchanged.
- Adding an existing person no longer overwrites their name, contacts or notes.
- Managers can edit only active coaches at their studios, and never change the login email.
  The person page shows the edit form only when the save would be allowed.
- Exact email matching; a half-finished invite can be retried.
- Rules are in a small new file `src/lib/people-policy.ts` with 46 tests (`node --test`).

### How it was checked
- Tests fail on the old logic and pass now; type check, lint and build pass.
- Clicked through on the demo as a manager: adding the Owner, another studio's coach, or
  yourself is refused and writes nothing; opening a former coach's page redirects; the Owner
  still opens and edits everyone.

### Changes how shared coaches are added
Managers can no longer add a coach from the other studio; you or the GM do it. We've asked
you about this (question 17).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

# Phase 2 pull requests, fix #2 (drafts, 21 Nov 2026)

| PR | Branch | Commit | What |
|---|---|---|---|
| 5 | `crew/fix-2-pay-rates` | `248f8f0` + `e5e4e3c` (on top of PR 3) | Audit #2, database half: migrations 0009 + 0010 + tests |
| 6 | `crew/fix-2-app-rates` | `d17f3eb` (on top of PR 4) | Audit #2, app half: screens read rates through the new functions |

**Release order (matters):**
1. Kelvin runs **0009** in the SQL editor. Changes nothing visible; safe any time.
2. Merge PR 6 (Vercel deploys the app). Deployed before step 1 is safe too: the pages just say
   the rates could not be loaded, and nothing is overwritten.
3. Kelvin runs **0010** in the SQL editor. This is the step that hides the rates. Running it
   before step 2 would break the Owner's studio settings page and the managers' PT/Challenge
   pages until the app deploys.

Rollback of 0010 (one line, in the SQL editor): `grant select (lead_rate, support_rate, lead_covering_support_rate, challenge_coach_pct, pt_coach_pct) on public.studios to authenticated;`
(column-level on purpose, so it never gives back the QR code hidden by fix #3)
Both files are all-or-nothing: if one fails, nothing in it is applied.

Things that must not happen (each is safe to undo, but would stop PT logging or break screens):
- **0010 needs 0009 first.** 0010 now checks this itself and refuses with "run migration 9
  first" (nothing changed) if 0009 is missing or incomplete.
- **Rolling the app back after 0010:** run the rollback line above *first*, then roll back the
  app. The old app reads the rate columns directly and its studio settings, PT and Challenge
  pages would fail.
- **If 0010 stops with an error:** nothing was changed. Run `rollback;` in the same SQL editor
  tab, then send us the message.

Push command (after Aaron's OK and Kelvin's write access; after PRs 1–4):

```bash
cd "/Users/aaron/Documents/BFT Project/app" && git push -u origin crew/fix-2-pay-rates crew/fix-2-app-rates
```

## PR 5: Fix: every coach could read the studio pay rates (database)

### Why
Our 14 Nov review (finding #2): any signed-in coach could read their studio's Lead and Support
rates, the "Lead covering Support" rule and the PT/Challenge %, straight from the database (no
screen showed them, but the data was reachable). Your plan says rates are Owner, GM and Finance
only. We reproduced it on our demo Supabase project: a coach read 80/60 and could guess rates
with filters.

### What changed (new migrations 0009 and 0010; your files 0001–0008 untouched)
- Nobody signed in can read those five studio columns directly any more; every other studio
  setting is readable exactly as before.
- Owner, GM and Finance read rates through a new function `studio_pay_settings()`.
- A studio's manager reads only their studio's default PT and Challenge % (their screens use it)
  through `studio_default_splits()`. We've asked you whether that's OK (question 18).
- A coach logging a PT session still gets the studio's default % stamped on it. To make that
  work, a coach can still ask the database for **their own studio's default PT %** (the same
  number shown on their PT sessions), even if they don't do PT. Never another studio's, and
  never the Lead/Support rates. We've included this in question 18.
- **Any new column added to `studios` from now on needs a `grant select` line** (written at the
  top of 0010; test 90 fails until it's added).

### How it was checked
- New test file `90_fix2_pay_rates.sql` (367 checks) fails on the old code (287 failures) and
  passes now; the who-sees-what matrix changes only in the pay cells. 61 scenarios apply the real
  0010 to broken databases and check it refuses and changes nothing (they run with plain
  `run.sh`; `--no-scenarios` skips them). Full suite passes in UTC and Malaysia time; 29
  deliberately weakened versions are each caught; running 0009 alone, the rollback line, and
  running both files twice are all tested. An independent second review passed it.
- On our demo Supabase project (real hosted API): coach, manager and owner direct reads are
  refused; Owner/Finance get rates through the function; Owner saving and adding a studio, and
  PT logging, still work.

To re-run the "0009 only" and "rollback" checks from the repo root:

```bash
git show crew/fix-1-private-details:supabase/tests/70_access_matrix.sql > /tmp/70_before_fix2.sql && supabase/tests/run.sh --stop-after 20260928000009 --no-tests --extra tests/10_stage1.sql --extra tests/20_class_types_notes.sql --extra tests/30_gm.sql --extra tests/40_challenges_pt_reviews.sql --extra tests/50_claiming.sql --extra tests/60_stage2b.sql --extra /tmp/70_before_fix2.sql --extra tests/80_fix1_private_details.sql crew_fix2_r11
```

```bash
git show crew/fix-1-private-details:supabase/tests/70_access_matrix.sql > /tmp/70_before_fix2.sql && echo 'grant select (lead_rate, support_rate, lead_covering_support_rate, challenge_coach_pct, pt_coach_pct) on public.studios to authenticated;' > /tmp/rollback_0010.sql && supabase/tests/run.sh --extra /tmp/rollback_0010.sql --extra /tmp/70_before_fix2.sql crew_fix2_r12
```

🤖 Generated with [Claude Code](https://claude.com/claude-code)

## PR 6: Fix: read pay rates through the new functions (app)

### Why
After PR 5, the Owner's studio settings page, the admin home "rates not set" banner and the
managers' PT and Challenge pages can no longer read the rate columns directly.

### What changed
- Those four screens read rates through the new functions. Nothing else changes on screen.
- If rates can't be loaded, the settings page says so and saving leaves the stored rates alone;
  the admin home says "Pay rates could not be checked" instead of guessing.
- An empty % box is now refused instead of being saved as 0 (studio settings, new challenge,
  PT approval).
- New tests (`node --test src/lib/*.test.mjs`, 102 passing), including a guard that fails if any
  code reads the rate columns from `studios` directly.

### How it was checked
- Tests fail on the old code and pass now; type check, lint and build pass.
- Clicked through on the demo after both migrations: Owner settings page shows the right rates
  and saving another setting leaves them untouched; the "rates not set" banner appears for a
  studio with a missing rate; the manager's PT page shows "60% coach / 40% studio" and the
  Challenge form prefills 40%; coach screens (shifts, slots, PT) load as before.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

# Phase 2 pull requests, fix #3 (drafts, 21 Nov 2026)

| PR | Branch | Commit | What |
|---|---|---|---|
| 7 | `crew/fix-3-checkin` | `26e6010` (on top of PR 5) | Audit #3, database half: migrations 0011 + 0012, an update to 0010, tests |
| 8 | `crew/fix-3-app-checkin` | `e68a9a0` (on top of PR 6) | Audit #3, app half: QR page and "Make a new code" |

**Before release:** check that `NEXT_PUBLIC_SITE_URL` is set in Vercel to the full site address
(e.g. `https://bft-coach-hub.vercel.app`). Without it the QR page now says "Site address not set"
instead of printing a QR code that phones can't open.

**Release order:**
1. Kelvin runs **0011** in the SQL editor (changes nothing visible).
2. Merge PR 8 (app deploys).
3. Kelvin runs **0012** (this hides the code; it refuses with a clear message if 0010 or 0011 is
   missing, and changes nothing in that case).
4. **Each studio manager makes a new code once and reprints it.** This kills every old link in
   coaches' phone history and every photo of the old code.

Rollback of 0012 (one line): `grant select (checkin_token) on public.studios to authenticated;`
If a file stops with an error: nothing was changed; run `rollback;` in that tab and send us the
message. Don't edit the description of the `checkin_token` column in Supabase's Table Editor
(migration 10 reads a tag in it).

Push command (after Aaron's OK and Kelvin's write access; after PRs 1–6):

```bash
cd "/Users/aaron/Documents/BFT Project/app" && git push -u origin crew/fix-3-checkin crew/fix-3-app-checkin
```

## PR 7: Fix: any coach could check in without being at the studio (database)

### Why
Our 14 Nov review (finding #3): the QR code's secret could be read from the database by any coach,
so they could check in from home; and a studio manager's "Make a new code" silently did nothing.
Reproduced on our demo Supabase project.

### What changed (new migrations 0011 and 0012; an update to 0010)
- Nobody signed in can read the code directly any more. The studio's own manager and you/the GM
  get it through `studio_checkin_token()` (the QR page uses this).
- The studio's manager (and you/the GM) can make a new code with `rotate_checkin_token()`; the
  old code stops working at once. Coaches, other studios' managers and Finance are refused.
- Finance no longer sees the code (question 2/19). Coaches check in by scanning exactly as before.
- 0010 (from PR 5, not yet run anywhere) is updated so it can never give the code back if re-run
  later, and its rollback line now only restores the pay columns.

### How it was checked
- New test file `95_fix3_checkin_token.sql` (323 checks) fails on the old code (224 failures) and
  passes now; 111 scenarios cover every run order, rollbacks and an emergency lock-down; 13
  deliberately weakened versions are each caught; full suite in UTC and Malaysia time.
- On our demo Supabase project: before, a coach could read the code; after, every direct read is
  refused; a manager made a new code from the QR page, the old link then said "This QR code isn't
  valid any more", and the new one worked. An adversarial checker passed it after two rounds, plus
  two independent reviews.

### What it can't stop
A printed code can still be photographed. Making a new code is the remedy; a self-changing code
or a location check would be a new feature (question 19).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

## PR 8: Fix: QR page reads and renews the code safely (app)

### What changed
- The QR page reads the code through the new function and never shows a broken QR.
- "Make a new code" now works for the studio's manager too, asks "The printed code will stop
  working straight away" first, and shows success or why it failed. After a change the page always
  shows the current code.
- A guard test fails if any code reads or writes the QR code column directly.

### How it was checked
- 136 tests pass (new ones fail on the old code); type check, lint and build pass.
- Clicked through on the demo as a manager (make a new code, page shows it) and as a coach
  (QR page redirects; old link refused).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

# Phase 2 pull requests, fix #4 (drafts, 21 Nov 2026)

| PR | Branch | Commit | What |
|---|---|---|---|
| 9 | `crew/fix-4-verified-lock` | `51d5bb2` (on top of PR 7) | Audit #4, database half: migration 0013 + tests |
| 10 | `crew/fix-4-app-lock` | `74bdbbf` (on top of PR 8) | Audit #4, app half: verify page shows locked classes; refusals shown |

**Release:** Kelvin runs **0013** in the SQL editor, then merge PR 10. Either order is safe: the
old app works with 0013 (it just shows refusals as text), and the new app works before 0013 (it
hides buttons a manager would only get refused on). 0013 is all-or-nothing and prints how many
existing classes were verified before they started or verified and then cancelled (left as they
are). Rollback: re-run migrations 0003/0006/0007's function definitions and drop the two triggers
(`classes_guard_lock`, `positions_guard_lock`); we will supply the exact SQL with the PR.

Push command (after PRs 1–8 and write access):

```bash
cd "/Users/aaron/Documents/BFT Project/app" && git push -u origin crew/fix-4-verified-lock crew/fix-4-app-lock
```

## PR 9: Fix: verified classes could still be changed (database)

### Why
Our 14 Nov review (finding #4): after verifying, a manager could still change attendance
("attended" to "no-show"), set attendance on cancelled or future classes, and a future "no-show"
opened an absence that could become a strike. Your plan says verified classes lock.

### What changed (new migration 0013)
- Once a class is verified, a studio manager can't change its attendance, coaches, type or
  cancelled state, through the app or directly. You and the GM still can (question 20); the
  class stays verified.
- Attendance can only be set on a class that has started and wasn't cancelled; a class can only
  be verified once it has started.
- Check-in skips verified classes. Rejecting a swap and deciding absences still work.

### How it was checked
- New test file `96_fix4_verified_lock.sql` (222 checks) fails on the old code (147 failures) and
  passes now; full suite in UTC and Malaysia time; 36 deliberately weakened versions caught.
- An adversarial checker found two gaps along the way (four internal functions that bypassed the
  lock, and a refusal that revealed a class's state) — both fixed — and then passed it; two
  independent reviews, including a two-session locking test.
- On our demo Supabase project: a manager verified a class, then every change was refused; the
  owner corrected it and it stayed verified; future classes refused attendance and verification;
  no absences created.

### Known limits (written in 0013)
Two people editing the same position at the same instant through the raw API can get a
"deadlock detected" error (retry works, no wrong data); there is no history of Owner/GM
corrections yet (question 20).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

## PR 10: Fix: verify page shows locked classes; refusals shown (app)

- A manager sees a verified class as "Verified — locked" with the recorded statuses and no
  buttons; Owner/GM keep the controls with a note.
- Every refusal is shown in plain words; "approve all" and changing a day's class type finish the
  rest and name each refused class; swap and absence decisions now show refusals and keep the
  typed note.
- 170 tests pass; type check, lint and build pass. Clicked through on the demo as manager and
  owner.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

# Phase 2 pull request, fix #5 (draft, 21 Nov 2026)

| PR | Branch | Commit | What |
|---|---|---|---|
| 11 | `crew/fix-5-lead-positions` | `ce64d86` (on top of PR 9) | Audit #5: migration 0014 + tests (database only) |

**Release:** Kelvin runs **0014** in the SQL editor. No app change; the app already uses the
checked actions. 0014 is all-or-nothing and prints how many current spots hold a coach who isn't
eligible for that spot today (left as they are — Kelvin can review them).

Push command (after PRs 1–10 and write access):

```bash
cd "/Users/aaron/Documents/BFT Project/app" && git push -u origin crew/fix-5-lead-positions
```

## PR 11: Fix: managers could put any coach into a Lead spot directly

### Why
Our 14 Nov review (finding #5): the Assign button checks Lead status, but writing straight to the
database let a manager put anyone in a Lead spot (no Lead status, other studio, not a coach).
Lead spots pay the Lead rate.

### What changed (new migration 0014)
- A studio manager can only change who coaches a class through Assign / claim / swaps, which
  check Lead status, the studio, clashes and one spot per class.
- You and the GM can still correct a coach directly (e.g. a past class), but only with a coach who
  is allowed in that spot today.
- Approving a waiting swap re-checks the incoming coach (Lead status could have been removed while
  it waited).
- A class with coaches on it can't be moved to the other studio.

### How it was checked
- New test file `97_fix5_lead_positions.sql` (165 checks) fails on the old code (88 failures) and
  passes now; full suite in UTC and Malaysia time; 25 deliberately weakened versions caught.
- An adversarial checker found three more ways around the first plan (swap approval, class moves,
  and managers granting then removing Lead status); the first two are fixed, the third is your
  question 21. Plus an independent review.
- On our demo Supabase project: a manager's direct writes were all refused; Assign still refused a
  non-Lead coach and worked for a Lead coach; the owner's direct writes refused ineligible coaches.

### Not covered (question 21)
A manager can still give a coach Lead status, assign them, then take the status away.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

# Phase 2 pull requests, fix #6 (draft, 22 Nov 2026)

| PR | Branch | Commit | What |
|---|---|---|---|
| 12 | `crew/fix-6-challenge-shares` | `eafcfd3` (on top of PR 11) | Audit #6: migration 0015 + tests (database) |
| 13 | `crew/fix-6-app-shares` | `f24ca8f` (on top of PR 10) | Audit #6: challenge form checks the split (app) |

**Release:** either order is safe. Recommended: Kelvin runs **0015**, then the app deploys the same
day (until both are live the form's amount preview can differ from the saved amount by a sen).
0015 is all-or-nothing and prints three counts: challenges whose shares don't add up to 100%,
challenges that pay out more than their pool, and coach rows whose stored amount differs from the
new rounding. Existing rows are left as they are (money may already have been paid at those
amounts); Kelvin can review them. A challenge that already breaks the rule can only be repaired or
deleted, not otherwise edited.

Push commands (after PRs 1–11 and write access):

```bash
cd "/Users/aaron/Documents/BFT Project/app" && git push -u origin crew/fix-6-challenge-shares
```

```bash
cd "/Users/aaron/Documents/BFT Project/app" && git push -u origin crew/fix-6-app-shares
```

## PR 12: Fix: Challenge shares could add up to more than 100% (database)

### Why
Our 14 Nov review (finding #6): the database accepted shares of 60 + 40 + 50 and paid RM7,500 from a
RM5,000 pool. Rounding each coach up also overpaid: three shares of 33.333% paid RM500.01 from
RM500.00. Challenge payouts go straight onto coach invoices.

### What changed (new migration 0015)
- A challenge's shares must add up to 100% (only the rounding of 3-decimal shares is allowed, so
  33.333 × 3 is fine; 99% or 101% is refused). Checked when the save finishes, for everyone.
- Two saves to the same challenge at the same moment can't both get through.
- Each coach gets floor(pool × their share ÷ all shares), rounded down to the sen. Payouts never add
  up to more than the pool, and an even split pays everyone the same: RM2,500 three ways is
  RM833.33 each, with 1 sen left over (your hand-worked October month).
- The leftover sen goes to nobody for now — that is your pay question **Q-5**. Rounding down rather
  than to the nearest sen is part of the same question.

### How it was checked
- New test file `98_fix6_challenge_shares.sql` (102 checks) fails on the old code (50 failures) and
  passes now; real-commit and two-session race scripts; full suite and scenarios pass.
- An adversarial checker found two problems in our first plan (simultaneous saves, and rounding that
  couldn't give 833.33 × 3); both fixed. An independent review found nothing blocking. App and
  database amounts were compared on about 23,000 generated cases: identical to the sen.
- On our demo Supabase project through the real API: 60/40/50 refused with a clear message and
  nothing saved; an even three-way split saved 833.33 each.

### Known limit
Two people editing the same challenge's shares through the database at the same instant can get a
"deadlock" error for one of them; the data stays correct. The app has no edit screen, so only direct
API use can hit it.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

## PR 13: Fix: Challenge form checks the split before saving (app)

### Why
The form only warned in red when shares were more than 0.05% off and still let you save; its amount
preview used rounding that could differ from what the database saves.

### What changed
- Save is disabled, with the reason and the current total, until shares add up to 100%.
- "Split evenly" gives every coach the same share, so everyone gets the same pay.
- Typed values are checked exactly (no silent rounding of extra decimals); the server checks the
  same before saving anything.
- Each coach's amount shown in the form is exactly what the database will save.

### How it was checked
- 20 new tests (fail on the old code); all 190 app tests, type check, lint and build pass.
- On the demo as a studio manager: a 60/40/50 split showed "Can't save yet: … 150.000%" with Save
  disabled; Split evenly showed RM833.33 each and saved 833.33 × 3; no sideways scroll at phone width.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

# Phase 2 pull request, fix #7 (draft, 22 Nov 2026)

| PR | Branch | Commit | What |
|---|---|---|---|
| 14 | `crew/fix-7-staging-backups` | `3d4490c` (on top of PR 12) | Audit #7: `ops/` staging and backup kit (no app or database change) |

**Release:** merging changes nothing in the app or the database. Then follow `ops/README.md` step by
step (Kelvin's account steps first). Best merged **before** PRs 3–13 are released, so their database
changes go through the kit instead of the SQL editor (see the note at the top of this file).

Push command (after PRs 1–13 and write access):

```bash
cd "/Users/aaron/Documents/BFT Project/app" && git push -u origin crew/fix-7-staging-backups
```

## PR 14: Staging copy and backups (ops kit)

### Why
Our 14 Nov review (finding #7): every push to `main` goes straight to live coaches, database
changes are pasted by hand with no record, and the Free plan has no backups and pauses when idle.

### What changed (new folder `ops/`, nothing else in the app)
- `ops/migrate.sh`: runs database changes in order and keeps a record of what ran. A failed file
  changes nothing; an edited or out-of-order file is refused; production refuses unless staging
  already ran exactly the same files and you type the project name.
- `ops/seed/`: fills a staging project with fake people, and refuses if it finds real ones.
- `ops/backup.sh` + `ops/restore-check.sh`: encrypted backup (sign-in sessions left out) and a check
  that proves the backup restores, table by table.
- `ops/schema-diff.sh`: compares two databases' structure.
- Nightly backup on GitHub, switched off until you add its secrets.
- `ops/README.md`: your one-time setup in order, the release flow, backup and restore.

### How it was checked
- 283 kit tests (they fail before the kit exists). An adversarial checker found holes over three
  rounds (backups could be written into a code folder; three ways a cleverly written file could
  half-apply; restore steps in the wrong order) — all fixed, final round passed. An independent
  review found nothing blocking.
- On our demo project: a backup restored with every table and count matching (57 tables).

### Needs you
Supabase Pro, the staging project, Vercel preview settings, GitHub secrets, invites — and
questions 22–26.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

# Phase 2 pull requests, fix #8 (draft, 24 Nov 2026)

| PR | Branch | Commit | What |
|---|---|---|---|
| 15 | `crew/fix-8-absence-deadline` | `fce547c` (on top of PR 14) | Audit #8: migration 0016 + tests (database) |
| 16 | `crew/fix-8-app-absence` | `1cf527a` (on top of PR 13) | Audit #8: absence deadline on the coach and manager pages (app) |

**Release:** deploy the app (PR 16) first or in the same window, then
`ops/migrate.sh staging --up-to 20260928000016`, check, then production. 0016 prints how many
existing late answers become strikes and how many coaches become booking-paused (counts only), so
you can tell those coaches before it goes live.

## PR 15: Fix: late absence answers removed the strike (database)

### Why
Our 14 Nov review (finding #8): a coach could explain a no-show after the 5-day deadline and the
strike disappeared at once, before any manager looked — which could also lift a booking pause.

### What changed (new migration 0016)
- Explanations are refused after the deadline; a missed deadline stays a strike unless the manager
  excuses it. An answer sent on time can't be re-edited after the deadline.
- A manager can't decide their own absence or change a decision already made (you and the GM can).
- The no-show notification shows the deadline with its time, in the studio's time zone.
- Coaches can delete their own evidence photo only if no absence uses it (so a refused late answer
  doesn't leave a medical certificate behind).
- People who aren't signed in can no longer look up strike counts.

### How it was checked
- New test file `99_fix8_absence_deadline.sql` (109 checks) fails on the old code (56 failures) and
  passes now; two-session race scenarios; full suite and the ops kit tests pass.
- An adversarial checker found three more problems in the first plan (managers excusing their own
  absence or flipping decisions, strike counts readable by anyone, a date-only deadline that would
  refuse an evening reply) — all fixed. An independent review: nothing blocking; its one should-fix
  is fixed.
- On our demo project through the real API: a late answer was refused with the clear message and the
  strike stayed; the notification read "Reply by Sun 29 Nov, …" with the time; signed-out lookups of
  strike counts were refused; a coach could delete their own unused photo but not one an absence uses
  or another person's; a second decision by a manager was refused.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

## PR 16: Fix: absence deadline shown and enforced on the pages (app)

### What changed
- Coach page: the deadline with date and time; after it, no form — "speak to your manager".
- `/shifts`: the no-show banner says when the deadline has passed.
- Manager page: missed and late answers appear under "To review" with **Excuse (no strike)** and
  **Confirm strike**; an "answered late" label.

### How it was checked
- 29 new tests on a frozen clock (fail on the old code); 219 app tests, type check, lint, build pass.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

# Phase 2 pull requests, fix #9 (draft, 24 Nov 2026)

| PR | Branch | Commit | What |
|---|---|---|---|
| 17 | `crew/fix-9-strike-window` | `9eda5ec` (on top of PR 15) | Audit #9: migration 0017 + tests (database) |
| 18 | `crew/fix-9-app-strike` | `b461041` (on top of PR 16) | Audit #9: "strike" shown only when it counts (app) |

**Release (order matters):** run **0017 first** (`ops/migrate.sh staging --up-to 20260928000017`,
check, then production), **then** deploy the app (PR 18). The app reads a new column that 0017 adds;
before it, the absence pages would show nothing. 0017 prints how many strikes stop counting and how
many coaches' booking pauses lift (counts only).

## PR 17: Fix: strikes counted from when the no-show was marked, not the class (database)

### Why
Our 14 Nov review (finding #9): a no-show for a class from 100 days ago, marked today, counted as a
fresh strike for 90 days and could pause the coach's booking.

### What changed (new migration 0017)
- A strike now counts for the studio's strike window from the class date. The class time is saved on
  the absence when the no-show is recorded, so later edits to the class can't stretch or erase a
  decided strike.
- Messages to coaches no longer say "this counts as a strike" when it doesn't (class outside the
  window, or forgiven by "resume booking").
- The 5 days to explain still start when the no-show is marked (question 28).

### How it was checked
- New test file `99b_fix9_strike_window.sql` (122 checks) fails on the old code (84 failures) and
  passes now; full suite, scenarios and ops kit tests pass.
- The adversarial checker found that moving a class's date after marking could stretch or erase a
  strike (fixed by saving the class time on the absence), and messages that promised strikes that
  wouldn't count (fixed). Independent review: nothing blocking.
- On our demo project: 0017 applied; a no-show for an old class was not counted, the coach was told
  it won't count, and signed-out users can't query it.

### Known limits (audit #13)
A manager can still clear an undecided absence by re-marking attendance after moving the class, and
deleting a class deletes its absences. Both belong to our fix #13 (direct class edits).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

## PR 18: Fix: "strike" shown only when it counts (app)

- Coach page, shifts banner and manager absences page ask the database whether an absence counts and
  say "strike" only when it does; outside the window they say it won't count.
- 232 app tests, type check, lint, build pass. Needs PR 17's migration first.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

# Phase 2 pull request, fix #10 (draft, 25 Nov 2026)

| PR | Branch | Commit | What |
|---|---|---|---|
| 19 | `crew/fix-10-noshow-correction` | `afbaaee` (on top of PR 17) | Audit #10: migration 0018 + tests (database) |

**Release:** after 0017: `ops/migrate.sh staging --up-to 20260928000018`, check, then production.
No app change is needed (the app shows the database's messages). 0018 prints how many existing
absences sit on positions already corrected to attended/late (counts only; nothing is changed,
question 35).

## PR 19: Fix: correcting a no-show to "attended" left the strike (database)

### Why
Our 14 Nov review (finding #10): after a manager decided a no-show, correcting it to "attended"
or "late" left the strike and any booking pause in place.

### What changed (new migration 0018)
- Correcting a no-show to attended or late removes its absence (and the strike), keeps a copy in a
  new record only the Owner and GM can read, and tells the coach: "Your no-show for … was changed
  to attended. It won't count as a strike." (+ "Booking is open again." when it applies).
- Only the Owner or GM can correct a no-show that was already decided (as in fix #8).
- Nobody except the Owner or GM can mark their own attendance or remove an absence of their own.
- Managers can't remove a no-show that belongs to a coach who no longer holds the position.
- Two people acting at once are handled with row locks; "Booking is open again" is sent once.
- Migrations 0016 and 0017 now refuse to run again after 0018.

### How it was checked
- New test file `99c_fix10_noshow_correction.sql` (113 checks) fails on the old code and passes
  now; full suite, three time zones, the two-session race script (10 runs in a row), and the
  migration scenarios pass.
- Three rounds with the adversarial checker and an independent review. Holes found and closed: a
  manager-coach erasing their own no-show by handing the slot to someone else, a same-moment race,
  the wrong class time in the notice, and a false "changed to attended" message.
- On our demo project: 0018 applied; a manager's correction of a decided no-show was refused; the
  GM's correction removed the strike and lifted the pause; the coach got the message; managers
  can't read the record; deciding the removed absence says "This absence no longer exists."

### Known limits (audit #13)
A manager-coach can still get their own undecided no-show removed by moving the class into the
future, handing the slot away and back, scanning in late, and waiting for another manager to
verify. This needs the direct class-time edit that our fix #13 closes. Deleting a class still
deletes its absences (also #13).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

# Phase 2 pull request, fix #13 (draft, 25 Nov 2026)

| PR | Branch | Commit | What |
|---|---|---|---|
| 20 | `crew/fix-13-class-edits` | `a25a597` (on top of PR 19) | Audit #13: migration 0019 + tests (database) |

**Release:** after 0018: `ops/migrate.sh staging --up-to 20260928000019`, check, then production.
No app change (the app never edits classes directly). If an end check aborts, its message names the
table, its owner and the role running it; nothing is half-applied. Already applied cleanly on our
demo project, which is a real Supabase project.

## PR 20: Fix: managers could edit classes directly, skipping the app's checks (database)

### Why
Our 14 Nov review (finding #13): a manager could change a class's time or headcount, cancel it in
someone else's name, flag it as a special event, add past classes or delete classes straight through
the database connection. No coach was told, and deleting a class erased its no-shows. A manager who
also coaches could use this to erase their own no-show or lateness.

### What changed (new migration 0019)
- Classes and coach slots can't be written directly by anyone through the app's connection; every
  change goes through the app's own actions, which check the rules and notify coaches.
- A class or slot with a no-show on record can't be deleted (cancel it instead); a slot with
  attendance can't be removed.
- Once attendance or a no-show is recorded on a slot, its coach can't be changed (this closes the
  remaining routes from fixes #9 and #10).
- Managers can't generate classes for past dates (Owner/GM can back-fill).
- Whole tables can't be emptied in one go, even with the server key.
- Existing data is left as it is and counted.

### How it was checked
- New test file `99d_fix13_class_edits.sql` (164 checks) fails on the old code (115 failures) and
  passes now; all earlier test files, the race scripts and the ops kit tests pass.
- Two rounds with the adversarial checker (final: PASS) and an independent review (nothing
  blocking).
- On our demo: 0019 applied; as a manager and as the Owner, editing, inserting or deleting a class
  was refused; reading still works; generating past classes was refused; after a no-show, neither
  the manager nor the Owner could hand the slot to someone else.

### Questions for you (36–40)
Walk-in substitutes after a class starts, who may move class times, special events, deleting
classes, and strikes on cancelled classes.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR 21: Fix: full-time coaches could drop or swap away classes their manager scheduled (database)

Branch `crew/fix-11-fulltime-drop` (on `crew/fix-13-class-edits`). Release after PR 20.

### Why
Our 14 Nov review (finding #11): a full-time coach could press Drop on a class their manager
assigned, or offer it to another coach as a swap, and be off it without the manager deciding. A
full-timer could also pick up classes by accepting someone's swap, which got round the existing
"full-time coaches are scheduled by their manager" rule. Your build plan says a full-time coach's
schedule is read-only and set by the manager.

### What changed (new migration 0020)
- Full-time coaches can't drop a class, ask for a swap, or accept one (they can still decline). A
  full-timer who manages that studio can still drop. Managers move classes with Assign, as before.
- Coaches marked inactive (in the app or at that studio) can't drop or swap.
- Swap requests already open with a full-timer on either side are refused when accepted or
  approved; those open when the change runs are cancelled and both coaches are told.
- Part-time rules are unchanged.

### How it was checked
- New test file `99e_fix11_fulltime.sql` (74 checks) fails on the old code (36 failures) and passes
  now; all earlier test files, scenarios (including a race between a drop and an employment-type
  change) and the ops kit tests pass.
- Adversarial checker: PASS in round 1. Independent review: nothing blocking.
- On our demo: as the full-time coach, Drop and asking for a swap were refused; a part-timer
  couldn't send a swap to the full-timer; a part-timer could still drop as before.

### Questions for you (41–44)
Part-timers dropping manager-assigned classes, swaps between full-timers, coaches who are full-time
at one studio and part-time at another, and telling the manager when a class opens up.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR 22: Fix: hide Drop and Swap from full-time coaches (app)

Branch `crew/fix-11-app-drop` (on `crew/fix-9-app-strike`). Release with or after PR 21.

### What changed
- One rule (`src/lib/shift-policy.ts`) decides Drop and Swap on "My shifts" and the studio week
  page, so the two pages agree.
- Full-time coaches see "Scheduled by your manager" instead of Drop/Swap (a full-timer who manages
  the studio still sees Drop). They are not offered as swap partners, and an incoming swap shows
  only Decline.
- On the studio week page, a part-timer's class assigned by someone else now shows "Assigned by
  your manager" instead of Drop, the same as "My shifts" already did.

### How it was checked
- 20 new checks (fail on the old code, pass now); all 252 app checks, type check, lint and build
  pass. Checker: logic PASS; the screens have not yet been looked at on a phone.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR 23: Fix: managers could approve their own PT, and approved PT could be changed silently (database)

Branch `crew/fix-12-pt-approval` (on `crew/fix-11-fulltime-drop`). Release after PR 21.

### Why
Our 14 Nov review (finding #12): a manager who also coaches could approve their own PT at 100% (the
studio got nothing), in the app with two clicks, and by at least four other routes. Approved PT could
later be changed (amount, split, date into another pay month, coach) or deleted with no record, and
the approver's name could be faked. Inactive coaches, Finance, and people from other studios could
have PT logged.

### What changed (new migration 0021)
- A studio manager can't approve, reject or set the split on their own PT; another manager, you or
  the GM must. You and the GM may approve your own (recorded).
- Approved or rejected sessions are locked for managers. You or the GM can correct only the status,
  amount, split or note on someone else's session. Nobody can move a session to another date, coach
  or studio, or delete a decided one.
- Who logged a session, who approved it and when are set by the database and can't be faked.
- PT can only be logged for an active coach or manager of that studio, or for you/the GM.
- Every change to a PT session is kept in a new history only you and the GM can read.
- Existing sessions are left as they are and counted (none self-approved on our demo).

### How it was checked
- New test file `99f_fix12_pt.sql` (183 checks) fails on the old code (140 failures) and passes now;
  all earlier tests, scenarios (including two managers approving at the same moment) and the ops kit
  pass. Three rounds with the checker (final PASS); two independent reviews (nothing blocking).
- On our demo: the manager's own PT was saved as pending and approving it was refused; after she
  approved a coach's session, changing the amount, moving the date or deleting it was refused; the
  Owner could correct the amount but not the date; the history showed every step to the Owner and
  nothing to the manager.

### Questions for you (45–52)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR 24: Fix: no Approve button on your own PT, and refusals are shown (app)

Branch `crew/fix-12-app-pt` (on `crew/fix-11-app-drop`). Release with or after PR 23.

### What changed
- Managers don't see Approve/Reject on their own PT ("Another manager, the Owner or GM must approve
  this."). Errors are shown instead of silently ignored.
- Approval only goes through if the session still matches what the manager saw (a coach changing the
  amount meanwhile gets "This session was changed since you opened the page").
- Delete only on pending sessions; the "add a session for a coach" list shows only active coaches of
  that studio.

### How it was checked
- 41 new checks (fail on the old code, pass now); all 293 app checks, type check, lint and build pass;
  checker ran the app's queries against the new database as each role. Screens not yet viewed on a
  phone.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

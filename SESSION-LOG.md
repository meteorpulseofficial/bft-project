# BFT Coach Hub: session log

Every session ends with these four sections, newest first. An empty section says "none".

```
### <date>: <one-line title>

**Done & verified**: what, who proved it, how, when
**Done but unverified**: what, and what would confirm it
**Needs your approval**: ready, blocked on Aaron (or Kelvin), with the rollback
**Open**: found, not fixed, with the reproduction
```

### 2026-11-25: Phase 2 fix #12, PT self-approval and silent edits (/crew db + app)

**Done & verified**
- Pre-mortem (checker, 13:04Z, reproduced 3x): F1 manager self-approves at 100% (2 clicks in app);
  F2 four more routes (MC at other studio, move studio, reassign coach to self, un-approve/re-approve);
  F3 decided rows editable/deletable, no history; F4 reviewer/creator forgeable; F5/F6 PT for
  non-members, inactive, Finance; F7 refusals swallowed. App writes pt_sessions directly (no RPCs).
- Decisions: managers never approve/split own (Owner/GM may, recorded); coach/studio immutable;
  decided rows locked for managers, Owner/GM correct status/amount/%/note on others' only; no
  deletes of decided; server-set reviewer/creator/created_at; active coach of studio only; history
  table Owner/GM read; no date rule (parked).
- `crew/fix-12-pt-approval` 210e543 (on fix-11): 0021, pt_guard rules, pt_coach_status helper,
  pt_session_history + truncate guards. 99f (183 checks, 140 fail on base), fix12_apply.sh (S1–S5
  incl. race), 70/90/99d/fix11_apply updated (checker confirmed nothing weakened).
- `crew/fix-12-app-pt` 2ea1733 (on fix-11-app): pt-policy.ts (+41 tests); no Approve on own PT;
  refusals shown; approval only if amount/minutes/date/client still match what the manager saw;
  delete only pending; coach list = active members.
- Checker: R1 PASS; R2 FAIL (pt_coach_status answered a no-user-id caller; stale helper; test
  fingerprint) → fixed; R3 PASS (13:59Z). Reviewer R1 and final: nothing blocking.
- Demo ~14:10Z: 0021 applied (0 self-approved, 0 no-reviewer). Mei Ling: own PT saved pending,
  approve refused; after approving Aisha's at 60%, amount/date/delete refused; Owner amount
  correction OK, date move refused; Suresh can't log at Bangsar; history 8 rows to Owner, 0 to Mei
  Ling. Probe rows, history and notices removed (back to 4 PT rows).

**Done but unverified**
- PT screens at 390/1440 not looked at; PostgREST encoding of eq filters reviewed (not run over HTTP).

**Needs your approval**
- Push both fix-12 branches (after all earlier ones; Aaron can't push yet). Release after 0020.
- Kelvin questions 45–52.

**Open**
- Owner/GM "back to pending" lets the coach edit again (Q47). Deleting a studio still cascades PT.
- Client names with a raw newline (only via SQL/API) would always read "changed". Someone else
  deciding first shows the "changed" message rather than "decided". Both safe.
- Re-running 0009 after 0021 reopens the hole (ledger never re-runs).

### 2026-11-25: Phase 2 fix #11, full-timers dropping or swapping assigned classes (/crew db + app)

**Done & verified**
- Pre-mortem (checker, 11:50Z, reproduced twice): F1 full-timer drop; F2 offload by swap (approval
  off or on); F3 full-timer picks up a class by accepting a swap; F4 old swap rows still complete;
  F5 studio week page shows Drop to full-timers. Also inactive callers could drop.
- Decisions (orchestrator): key on employment_type (build plan: full-timer schedule read-only);
  no drop/swap/accept for full-timers, decline allowed; studio manager may still drop; inactive
  callers refused; open full-timer swaps cancelled + both notified; part-time DB rules unchanged.
- `crew/fix-11-fulltime-drop` 29b8d2d (on fix-13): 0020 + assert_caller_active helper; drop_position,
  request_swap, respond_swap, do_swap, swap_blocker, swap_target_blocker re-created. Tests 99e (74
  checks, 36 fail on base), scenarios/fix11_apply.sh (incl. race), baseline line.
- `crew/fix-11-app-drop` 4f60ab3 (on fix-9-app): src/lib/shift-policy.ts (+20 tests); /shifts and
  /studios/[id] use one rule; full-timers not swap targets; incoming swap = Decline only.
- Checker R1 PASS both halves (12:12Z); reviewer: nothing blocking.
- Demo 25 Nov ~12:14Z: 0020 applied ("…cancelled…: 0"). As Daniel (full-time): drop refused, swap
  request refused; Aisha → Daniel swap refused; Daniel still on class; Aisha (part-time) drop OK.
  Probe data restored (Aisha re-assigned with original assigned_by/claimed_at; 1 notice removed).

**Done but unverified**
- App screens at 390/1440 not looked at (no browser run); logic checked by tests and the checker.

**Needs your approval**
- Push both fix-11 branches (after #8–#10, #13; Aaron can't push yet). Release after 0019.
- Kelvin questions 41–44.

**Open**
- Someone switched to full-time later keeps their open swaps (accept/approve refused, not cancelled;
  their own outgoing request is hidden on /shifts so they can't withdraw it). Fails safe.
- Cancelling an awaiting_manager swap in the migration doesn't tell the manager.
- Approving an old swap whose requester became full-time shows the full-timer message to the
  manager; the row stays until Reject.
- App hides Drop from a full-time Owner/GM holding a position (DB would allow). Safe direction.
- Re-running 0007/0013/0014 after 0020 restores old bodies (ledger never re-runs).

### 2026-11-25: Phase 2 fix #13, direct class edits (/crew db)

**Done & verified**
- Pre-mortem: H1–H16, G1, T1 reproduced (direct time/headcount/cancel/type/special-event/studio
  edits, past inserts, deletes cascading no-shows away, H12-self own strike wipe, H14 own lateness
  wipe); fix #10 launder_back, N1, N2 reproduced. App makes no direct writes → db-only.
- Contract `contracts/fix-13-class-edits/CONTRACT.md` v3 + attack-list.
- `crew/fix-13-class-edits` a25a597 (on crew/fix-10-noshow-correction): 0019 — revoke writes +
  TRUNCATE (E1), absences FK RESTRICT + delete guards incl. attendance (E2), coach lock on
  positions with records (E3), set_class_type skips them (E8), generate_classes past = admin only
  (E5b), BEFORE TRUNCATE guard (E10), end checks name table/owner/role. Tests: 99d (164),
  fix13_apply.sh, 10/50/96/97/99b/99c updated.
- Checker R1 FAIL (attended position deletable) → fixed; R2 PASS (01:58Z). Reviewer R1 and R2:
  nothing blocking.
- Demo 25 Nov (real Supabase): 0019 applied with no end-check abort (staging question answered for
  the demo); result line "0 / 0 / 113 classes created after they started" (the seed back-fills 14
  days). Manager and Owner: update/insert/delete classes → permission denied; select works;
  manager generate past → refused; after a no-show, manager and Owner unassign → refused. Probe
  data removed.

**Done but unverified**
- App screens not clicked through after 0019 (no app writes to these tables; reads checked).
- Kelvin's production table owners (demo was fine).

**Needs your approval**
- Push crew/fix-13-class-edits (after #8–#10; Aaron can't push yet). Release after 0018.
- Kelvin questions 36–40 (Q-A walk-in substitute is business-critical).

**Open**
- No way in the app to fix a wrong coach after attendance is recorded (Q-36).
- Non-KL studios: app sends KL date to generate_classes (latent; all studios are KL).
- Stage 3 pay should read the coach from attendance.profile_id (old rows may have attended rows on
  an empty position).
- Fixes #11 and #12 not started.

### 2026-11-25: Phase 2 fix #10, correcting a no-show left the strike (/crew db)

**Done & verified**
- Pre-mortem (24 Nov): base already deleted UNDECIDED absences on attended/late; the hole was
  DECIDED absences (strike + pause stay), plus manager-coach self-correction.
- Contract `contracts/fix-10-noshow-correction/CONTRACT.md` v3 + attack-list (A-01–A-27).
- `crew/fix-10-noshow-correction` afbaaee (on crew/fix-9-strike-window): 0018 — absence copied to
  admin-only `absence_corrections` and deleted on attended/late; coach notice; D3 decided = Owner/GM
  only; D4 no self-marking / no removing own absence (verify_class exemption only with no absence);
  D12 owner-differs refused for managers; locks + per coach/studio advisory lock; decide_absence
  "This absence no longer exists."; 0016/0017 refuse re-run. Tests: 99c (113), fix10_apply.sh,
  fix8_race.sh races 1b–7, 70 matrix covers the new table.
- Three rounds. Reviewer: R1 blocking (absence owner vs position coach) → fixed; R2 clean. Checker:
  R1 PASS, R2 FAIL (reassign + another manager's mark/verify) → D12, R3 FAIL (see Open).
- Aaron accepted (25 Nov): commit now, close the remaining route in fix #13.
- Demo 25 Nov: 0018 applied (0/0/0/0). Ben no-show → decided invalid (strike true) → manager
  attended refused (D3 text) → GM attended ok, absence gone, "Attendance corrected … Booking is open
  again." notice, manager reads 0 records, GM reads 1, decide on removed id → "This absence no
  longer exists." Probe data removed.

**Done but unverified**
- Not checked in the app UI (no app change; messages come from the database).

**Needs your approval**
- Push crew/fix-10-noshow-correction (after #8, #9; Aaron can't push yet). Release after 0017.
- Kelvin questions 32–35.

**Open**
- Checker R3: manager-coach moves class to future, assign_position away and back to self, moves
  class back, scans late; another manager's verify_class removes MC's own undecided no-show (also on
  base). Script contracts/fix-10-noshow-correction/repro/launder_back.sql. Closes with #13 (direct class edits).
- N1: after reassignment, the new coach's real no-show records nothing. N2: deleting a class
  cascades absences away. Both #13.

### 2026-11-24: Phase 2 fix #9, strikes counted from marking, not the class date (/crew db + app)

**Done & verified**
- Contract `contracts/fix-9-strike-window/CONTRACT.md` v2 (D1–D6, E1–E7 + release order) +
  `attack-list.md` (A-01–A-29). Pre-mortem: hole reproduced (100/200-day-old classes → 2 strikes,
  paused); P1 class date editable after marking; P5 DST interval; D2 text promised a strike.
- `crew/fix-9-strike-window` 9eda5ec (on crew/fix-8-absence-deadline): 0017 — absences.class_starts_at
  + trigger, absence_strike_window / absence_is_strike / absence_window_status, strike_count inner
  join, absence_counts_as_strike (authenticated), texts follow window status (outside / forgiven),
  set_attendance lock text split so 0016 re-run is refused, result line. Test 99b (122; 84 failed on
  base), fix9_apply.sh, test 99 rows moved, test 70 one line.
- `crew/fix-9-app-strike` b461041 (on crew/fix-8-app-absence): strike wording from the DB answer;
  neutral app-clock refusal; reads class_starts_at.
- Checker round 1 PASS (02:17Z); fresh reviewer: nothing blocking (release order recorded; wording
  nits fixed).
- Demo 24 Nov: 0017 applied (0/0/0/0). Recent-class no-show → normal "Reply by Sun 29 Nov, 10:19am."
  notice; class_starts_at stored and readable by the coach; manager direct update of it → 0 rows;
  simulated old class decided invalid → "outside the strike window…" notice, strike_count 0,
  absence_counts_as_strike false, anon 42501. Probe data removed.

**Done but unverified**
- App pages not looked at in a browser.

**Needs your approval**
- Push crew/fix-9-strike-window and crew/fix-9-app-strike (Aaron can't push yet). Release: 0017
  first, then the app. Rollback: re-run 0016's function bodies after dropping 0017's split guard is
  NOT supported by design; rollback = restore from backup or a reverse migration we write.

**Open**
- Questions 28 (updated), 30, 31. Audit #13: re-marking an undecided absence after moving a class
  clears it; deleting a class deletes its absences. Re-running migration 13 after 17 is unsafe (the
  ledger prevents it).

### 2026-11-24: Phase 2 fix #8, late absence answers removed the strike (/crew db + app)

**Done & verified**
- Contract `contracts/fix-8-absence-deadline/CONTRACT.md` v2 (D1–D6, E1–E7) + `attack-list.md`
  (A-01–A-39). Pre-mortem F1 (late answer drops strike, unpauses), F2 (manager self-decide / flip),
  F3 (anon reads strike counts).
- `crew/fix-8-absence-deadline` fce547c (on crew/fix-7-staging-backups): 0016 — submit_absence
  deadline refusal + order; strike_count counts undecided late answers; decide_absence role 42501
  first, no self-decide / no change after decision for non-admins, clean "no longer exists";
  set_attendance re-created (only the notification text: studio tz, 'Dy FMDD Mon, FMHH12:MIam');
  absence_evidence_in_use + storage policy evidence_delete; revoke five absence functions from
  PUBLIC/anon; result line. Test 99 (109; 56 failed on base), scenarios fix8_apply.sh and
  fix8_race.sh, test 80 R9-08 → 42501, ops kit tests count migrations from the folder (283/283).
- `crew/fix-8-app-absence` 1cf527a (on crew/fix-6-app-shares): src/lib/absence-deadline.ts (29
  tests), coach page, AbsenceForm, /shifts banner, manager absences page, decideAbsence.
- Checker round 1 PASS (01:32Z) locally; fresh reviewer nothing blocking (should-fix fixed with a
  race scenario; two app nits fixed).
- Demo 24 Nov: 0016 applied (0/0/0). As Mei Ling + coach Daniel via supabase-js: no-show
  notification "…Reply by Sun 29 Nov, <time>"; late submit → P0001 deadline text, strike count
  unchanged; anon strike_count → 42501; coach deleted own unused file, not a referenced one nor
  another's; manager second decision refused. Probe data removed (absence, notifications, files;
  that position's attendance rows were deleted too — demo data only).

**Done but unverified**
- The new coach/manager pages not looked at in a browser (390/1440); covered by unit tests and code
  reading only.

**Needs your approval**
- Push crew/fix-8-absence-deadline and crew/fix-8-app-absence; open PRs 15–16. Kelvin: app first or
  same window, then 0016 via ops/migrate.sh. Rollback: re-run 0007's submit_absence/strike_count/
  decide_absence and 0013's set_attendance bodies, drop policy evidence_delete, re-grant to anon.

**Open**
- Questions 27–29 for Kelvin. Signed-in coaches can read others' strike counts (Q29).
- Out of scope: re-marking a no-show resets the deadline (#10/#13 area); evidence path can point
  at another coach's file path; upload path trusts the form's studioId.

### 2026-11-23: All 14 crew branches pushed to Kelvin's GitHub (Aaron's OK)

**Done & verified**
- Aaron said "Push everything to GitHub". Pushed the 14 `crew/*` branches to
  github.com/bangsarmanagement/bft-coach-hub (write access works now). `git fetch` confirms every
  remote branch equals the local commit (b59ca81, caea2a5, 21fc26f, de28999, e5e4e3c, d17f3eb,
  26e6010, e68a9a0, 51d5bb2, 74bdbbf, ce64d86, eafcfd3, f24ca8f, 3d4490c). `main` not touched
  (still c1dae4e). No pull requests opened yet.

**Done but unverified**
- Vercel probably made Preview deployments for the new branches; their env vars likely point at
  production Supabase (fix #7 S11). Not checked (no Vercel access).

**Needs your approval**
- Opening PRs 1–14 (drafts in prep/phase1-pull-requests.md). Kelvin to release in the written order.

**Open**
- Demo baseline still waiting for Aaron's typed "yes".

### 2026-11-22: Phase 2 fix #7, staging and backup kit (/crew, ops)

**Done & verified**
- Contract `contracts/fix-7-staging-backups/CONTRACT.md` v2 (D1–D10, E1–E13) + `attack-list.md`
  (A-01–A-44, facts F1–F12). Demo is PG 17.12; pg_dump 17.12 works via the session pooler.
- `crew/fix-7-staging-backups` 3d4490c (on crew/fix-6-challenge-shares): `ops/` kit — migrate.sh
  (ledger in schema ops; one txn per file; every statement EXECUTEd inside a generated DO block so
  COMMIT/COPY/VACUUM are refused by Postgres; result lines as NOTICE; --baseline/--up-to/--dry-run;
  production guard needs typed ref + staging at same checksums; staging refused while
  ops/production-ref is the placeholder), seed/ (real-people guard before any write), backup.sh
  (openssl AES-256-CBC pbkdf2 iter 600000; auth sessions/tokens excluded), restore-check.sh,
  schema-diff.sh, ci/nightly-backup.sh + .github/workflows/nightly-backup.yml (off until secrets),
  README, kit tests 283/283 (11:06Z).
- Checker: round 1 FAIL (GIT_DIR bypass of the out-dir refusal; standard_conforming_strings hidden
  COMMIT; restore order), round 2 FAIL (lone CR hidden COMMIT), round 3 PASS 11:01Z. Fresh reviewer:
  nothing blocking each round; last items (README first-production order, error detail/context) fixed.
- Demo: backups restore-check PASS (57 tables, auth.users 13/13); REST refuses schema ops (406).
- Incident (owner, early build): fake-data encrypted test backups written into .crew-wt/fix-7 and
  Kelvin's checkout app/backups/; deleted at once, app/ git status clean, guard hardened (git-free
  walk-up + GIT_* cleared). Nothing pushed.
- Docs: PR 14 draft + migrate.sh note at top of prep/phase1-pull-requests.md (SQL editor → kit);
  questions 22–26 in prep/access-questions-for-kelvin.md.

**Done but unverified**
- Demo baseline `ops/migrate.sh demo --baseline 20260928000015` waiting for Aaron's typed "yes"
  (terminal tab "demo baseline"); then re-check R-11 on the demo with schema ops present.
- Linux bash, the GitHub runner (PGDG pg_dump 17), the 6543 pooler, real admin-API seed, restore
  into a real new Supabase project (README says UNTESTED) — need Kelvin's staging/GitHub.

**Needs your approval**
- Kelvin: Supabase Pro (~US$25/mo), staging project, Vercel previews → staging + protection,
  GitHub secrets, invites, questions 22–26. Push crew/fix-7-staging-backups after PRs 1–13.
  Rollback: none needed (kit changes nothing until used; drop schema ops to remove the ledger).

**Open**
- Storage files (absence evidence) are in no backup (incl. Supabase Pro) — Q25.
- Known limits in ops/README.md (identity check is text matching; SELECT INTO refused; big SELECTs
  print one NOTICE per row; demo target not checked against the placeholder ref).

### 2026-11-22: Phase 2 fix #6, Challenge shares adding up to more than 100% (/crew db + app)

**Done & verified**
- Contract `contracts/fix-6-challenge-shares/CONTRACT.md` v2.1 (D1–D8) + `attack-list.md` (A-01–A-32).
  Checker pre-mortem (00:42 UTC) found F1 (simultaneous saves both pass) and F2 (3-decimal % +
  round-down can't give 833.33 × 3 / golden month) → v2: shares are weights, rule
  |Σ−100| ≤ 0.0005·n, payout floor(pool × share/Σ), challenge row locked FOR NO KEY UPDATE.
  v2.1: a write that repairs a bad challenge passes; extra `set id = id` touch for REPEATABLE READ.
- `crew/fix-6-challenge-shares` eafcfd3 (on crew/fix-5-lead-positions): 0015
  `20260928000015_challenge_shares_total.sql` — challenge_split_ok, challenge_payout (one exact div),
  re-created challenge_coach_amount, definer challenge_shares_check + deferred constraint trigger
  challenge_coaches_shares_total (23514 "Challenge shares must add up to 100%. They add up to x%."),
  result line with 3 counts. Test 98 (102 checks; 50 fail on base), scenarios/fix6_commit.sql
  (--extra, real commits), scenarios/fix6_race.sh (5 races). Not wired into run_scenarios.sh.
- `crew/fix-6-app-shares` f24ca8f (on crew/fix-4-app-lock): src/lib/challenge-split.ts (integer/BigInt),
  test (20; 18 fail on base), createChallenge validates before insert, ChallengeForm Save disabled
  with reason, Split evenly equal shares.
- Checker round 1 PASS (01:09 UTC): suite 10–98 + 111 scenarios + fix6_commit + races; 4,000-case
  app-vs-DB scan identical. Fresh reviewer: nothing blocking; 19,432-row scan identical.
- Demo (22 Nov): 0015 applied (demo had 1 valid challenge, 0/0/0). supabase-js as Mei Ling:
  60/40/50 → 400 23514 150.000%, nothing saved; 33.333×3 of 5000×50% → 833.33×3; all-100 update →
  23514 300%. Browser (app on 3000 now from `.crew-wt/fix-6-app`): bad split shows "Can't save yet",
  Save disabled; Split evenly → RM833.33 each, saved 833.33×3; no sideways scroll at 375px.
  Test challenges deleted.
- Docs: PR 12–13 drafts in prep/phase1-pull-requests.md; Q-5 note (rounding down interim) in
  prep/stage3-pay-spec.md; REPOS next migration 0016; demo README.

**Done but unverified**
- none

**Needs your approval**
- Push crew/fix-6-challenge-shares and crew/fix-6-app-shares (after PRs 1–11 and write access).
  Kelvin runs 0015 then deploys the app the same day; read 0015's three counts on production.
  Rollback: drop trigger challenge_coaches_shares_total + restore 0005's challenge_coach_amount.

**Open**
- Known limit: two simultaneous direct edits of one challenge's shares can end in "deadlock
  detected" for one (data correct; checker dl.sh). No edit screen in the app.
- Out of scope (D8): non-members can be added as challenge coaches (cross-studio payout path,
  Stage 3); challenge lock once its month is paid (Stage 3); TRUNCATE grants hardening.
- Kelvin: Q-5 (leftover sen and rounding direction).

### 2026-11-21: Phase 2 fix #5, managers putting any coach into a Lead spot (/crew db)

**Done & verified**
- Contract `contracts/fix-5-lead-positions/CONTRACT.md` v2 (D1–D14) + `attack-list.md`.
- `crew/fix-5-lead-positions` ce64d86 (on crew/fix-4-verified-lock): 0014 — positions_guard_write
  (managers can't change id/coach/role/class/stamps, insert with a coach or delete filled spots;
  Owner/GM writes must be eligible, one per class, no clash, via definer helper
  position_admin_problem), classes_guard_studio (no studio move with coaches), swap_target_blocker
  re-check in do_swap/decide_swap (accepted deviation: target checks only, so fix #4's admin
  approval on started verified classes keeps working). 97 (165 checks; 88 fail on base); 96
  R09-mgr-pos-update flipped + R09-mgr-pos-seq, C01 trigger list; 20 setup uses assign_position.
  25 mutants; UTC + KL. bft-checker PASS (13:11Z) incl. P1/P3 now held; fresh reviewer nothing
  blocking; final tiny round closed the positions.id change (2 fail-first checks).
- Hosted demo (Claude, ~21:15 +08, scratchpad demo-attack5.mjs / demo5.txt): 0014 applied (0 odd
  rows); manager direct writes (non-Lead, other studio, eligible, insert, delete filled) all 42501
  "Use Assign…"; Assign refuses non-Lead (P0001) and works for a Lead; owner direct refuses
  ineligible coaches. Demo DB now 0008–0014.

**Done but unverified**
- Concurrency (two sessions) not tested for the new guards.

**Needs your approval**
- Push `crew/fix-5-lead-positions`, PR 11 (after PRs 1–10, write access). Kelvin runs 0014.

**Open**
- P2 / Q21: a manager can grant Lead status, assign, then revoke it (by design since fix #1).
- D13: Owner/GM can't correct an old class for a coach who has since lost Lead status or left.
- A manager or Owner can move an unverified class's start time onto another class and
  double-book a coach (audit #13).
- NEW (outside fix #5): on the hosted demo, `anon` and `authenticated` hold TRUNCATE on all 20
  public tables (Supabase default). The Data API can't issue TRUNCATE, but it bypasses RLS and
  triggers for any direct DB login with those roles. Worth a small hardening migration
  (`revoke truncate on all tables in schema public from anon, authenticated`) — needs its own
  check of Supabase tooling.

### 2026-11-21: Phase 2 fix #4, verified classes not locked (/crew db + app)

**Done & verified**
- Contract `contracts/fix-4-verified-lock/CONTRACT.md` v2 (D1–D16) + checker's `attack-list.md`.
- DB half `crew/fix-4-verified-lock` 51d5bb2 (on crew/fix-3-checkin): 0013 — assert_class_unlocked /
  class_locked helpers; set_attendance, verify_class, check_in, report_present, claim/drop,
  request/respond/decide swap, do_swap, assign_position, set_class_cancelled, set_class_type
  re-created with role-first 42501, P0001 rule refusals, lock checks (eligibility before lock);
  guard triggers on classes/positions; Known limits in header. 96 (222 checks; 147 fail on base),
  60 updated. 36 mutants; UTC + KL. bft-checker PASS (07:56 UTC) after finding S-1 (definer
  bypasses) and F2 (lock revealed to other-studio coach); two fresh reviews nothing blocking
  (incl. all 13 re-created bodies diffed and a two-session lock test).
- App half `crew/fix-4-app-lock` 74bdbbf: verify-lock.ts (classControls, cleanDbError,
  verifyClassResult, runOverClasses), verify page locked view, refusals shown everywhere incl.
  swaps/absences (ResultForm keeps the note), batch actions finish and name refused classes.
  170 tests, tsc/eslint/build 0. Checker PASS.
- Hosted demo (Claude, ~15:56 +08, scratchpad demo-attack4.mjs / demo4.txt): 0013 applied
  (0/0 odd rows); manager verified a class, then change/re-verify/un-assign/cancel/direct edits all
  refused; owner headcount-null kept 12, owner correction kept the class verified; future class
  attendance and verify refused; absences unchanged (2/2). UI: manager sees "Verified — locked"
  with recorded statuses, owner sees correction controls + note. Demo runs `.crew-wt/fix-4-app`.
  (One empty past class, 20 Nov 19:50, got verified by an early probe run — harmless.)

**Done but unverified**
- Concurrency only hand-tested (reviewer); 390px; live PostgREST 40P01 text in the app.

**Needs your approval**
- Push `crew/fix-4-verified-lock` + `crew/fix-4-app-lock`, PRs 9–10 (after 1–8, write access).
  Kelvin runs 0013; either release order is safe.

**Open**
- 40P01 deadlock possible between a definer function and a raw API position write (documented).
- class_locked() answers any signed-in user per class id (documented, D16).
- No history of Owner/GM corrections (Q20). Out of scope, recorded: #13 direct starts_at/status
  edits on unverified classes; #10 strike stays after correction / after cancelling; #8/#9 timing;
  on an unverified started class assign_position(NULL) and swap approval still delete check-ins.

### 2026-11-21: Phase 2 fix #3, QR check-in code readable by every coach (/crew db + app)

**Done & verified**
- Contract `contracts/fix-3-checkin/CONTRACT.md` v2 (D1–D18) + checker's `attack-list.md`.
- DB half `crew/fix-3-checkin` 26e6010 (on crew/fix-2-pay-rates): 0011 (`studio_checkin_token`,
  `rotate_checkin_token` via `= default`), 0012 (precondition incl. behavioural probe, sweep,
  column revoke, `[bft:fix3-token-hidden]` comment tag, end check), 0010 edited (D9 keep rule
  reads the tag; D10 column-level rollback), 95 (323 checks; 224 fail on base), 60/70/90 rewritten
  (D12), 111 scenarios incl. O01–O16 run orders and L01–L04 lock-down. 13 mutants caught; UTC + KL.
  bft-checker PASS (07:05 UTC) after one round (lock-down finding); fresh reviewer nothing blocking.
- App half `crew/fix-3-app-checkin` e68a9a0: QR page via RPC, qrLink (clean origin only, no
  /checkin/null), RotateButton (confirm, tap-time gate, messages), rotateFlow (re-read after
  rotate, refresh on any possibly-committed error); 136 tests, tsc/eslint/build 0. Checker PASS,
  reviewer nothing blocking.
- Hosted demo (Claude, 21 Nov ~15:00 +08, scratchpad demo-attack3.mjs, demo3-after0011/0012.txt):
  pgcrypto is in `extensions` there and rotate via the real API works (P4); after 0012 every direct
  read → 42501, manager gets the code via RPC, others null / 42501; re-running edited 0010 after
  0012 keeps it hidden; lock-down replay (table revoke → 0010) keeps it hidden. UI: manager QR page
  → confirm → "New code made…" and page shows the new stored code; coach → QR page redirects; old
  /checkin link → "This QR code isn't valid any more." Demo runs `.crew-wt/fix-3-app`, DB 0008–0012.
- Docs: PR 7/8 drafts (release incl. "each manager makes a new code once", Vercel site URL check,
  don't edit the column description), Q19 for Kelvin, fix #2 rollback line made column-level
  everywhere.

**Done but unverified**
- The `request.jwt.claims` clearing in 0012's self-test (local stub reads only claim.sub).
  390px layout of the QR page and a real phone scan. Whether Vercel has NEXT_PUBLIC_SITE_URL.

**Needs your approval**
- Push `crew/fix-3-checkin` + `crew/fix-3-app-checkin`, PRs 7–8, after PRs 1–6 and write access.
  Kelvin runs 0011 → app deploys → 0012 → managers renew codes. Rollback line in PR 7.

**Open**
- A printed code can be photographed (Q19: self-changing code / location check).
- Tag removed from the column comment + lock-down + 0010 re-run → token readable again
  (checker note A); tag added by hand without 0012 → 0010 hides it early (note B, fails closed).
- No record of who rotated a code; Owner/GM can still write a code directly (D15).

### 2026-11-21: Fix #2 follow-up, migration 10 refuses without 9 (/crew db bug)

**Done & verified**
- `crew/fix-2-pay-rates` e5e4e3c (on 248f8f0): 0010 precondition block (exact signatures,
  shapes, definer, search_path, owner, grants, no overloads; pt_guard = 0009 version via a
  literal-aware text check, BEFORE INSERT OR UPDATE row trigger; sweep for other invoker readers
  of studios incl. policy/view-dependent functions in any schema). 90 pins result shapes (367
  checks; 287 fail on 21fc26f). New tests/scenarios/ (61; old 0010 fails 48) run by plain
  run.sh. 29 mutants caught; UTC + KL; R-11/R-12; re-run ACL identical.
- bft-checker (review-3 checker) PASS twice (06:17, 06:29 UTC) incl. its F1/F3/N1/N2 repros;
  fresh reviewer nothing blocking. Review-3 F1 repro now aborts and coach/manager PT logging
  still works.
- Hosted demo (Claude, ~14:25 +08): polished 0010 re-run on the demo → passes its precondition
  and sweep (no false refusal from Supabase objects such as auth.uid()), studios table and
  column ACLs byte-identical before/after. Demo pt_guard md5 = local (e9db0021…).
- Docs: PR 5 numbers/commits updated, "rollback; then send us the message" added; contract
  D15 (precondition) and D16 (accepted limits).

**Done but unverified**
- Refusal paths of 0010 on hosted Supabase (only the success path run there, to keep the demo
  intact). Behaviour of the Supabase SQL editor after an abort (run `rollback;`), per reviewer.

**Needs your approval**
- Same as fix #2: push `crew/fix-2-pay-rates` (now 2 commits) + `crew/fix-2-app-rates`, PRs 5–6,
  after write access.

**Open**
- D16 accepted limits: `$` inside identifiers (`a$q$`) can hide code from 0010's reader
  (scratchpad/review3/fool3_guard.sql, fool3_sweep.sql); literal case ignored (upper-cased role
  names in pt_guard's exempt branch). Both need deliberate SQL-editor edits.

### 2026-11-21: Independent review of fix #2 (/crew review)

**Done & verified**
- Fresh bft-checker, all six lenses, 05:34–05:42 UTC: no leak found on local Postgres or the
  hosted demo (embeds, filters, casts, CSV, GET RPC, error text, other-studio, anon all held).
  90 fails 283 on base and passes; 70 fails 65 on base and passes; real 0009-only and rollback
  runs pass. App PASS: 102 tests, tsc/eslint/build, 24 demo pages × 8 roles load correctly.
- Hand-over docs corrected (Claude): PR 5 now warns never to run 0010 without 0009, to run
  the rollback line before rolling back the app, and what to do if 0010 aborts; it discloses
  that a coach can read their own studio's default PT %; Q18 extended; contract D12 amended
  (two PRs released together).

**Done but unverified**
- Owner save/add studio and PT logging on hosted after 0010 were verified earlier
  (demo-attack2.mjs), not re-run by this read-only review. Kelvin's production may hold
  objects not in the repo; a schema-only copy on staging would show them.

**Needs your approval**
- A short db round on `crew/fix-2-pay-rates`: F1 make 0010 refuse unless 0009 is applied
  (helper exists and pt_guard replaced); F3 pin the two functions' result columns in 90 and
  catch removal of 0010's check block. App lane needs no change.

**Open**
- F1 repro: `run.sh --stop-after 20260928000008 --no-tests --extra migrations/…000010… chk_x`,
  then a coach PT insert → "permission denied for table studios". Script
  scratchpad/review3/oo_probe.sql.
- F3 repro: mutant m7 (studio_default_splits also returns lead_rate, support_rate) passes the
  whole suite; m9 (0010 check block deleted) passes too. scratchpad/review3/m7/.
- F5 note: app guard misses `.gt("studio.pt_coach_pct", …)` through an embed and
  `.from(variable)`; none in code today, DB refuses it anyway.
- F6 note: coaches in a challenge see its coach % and revenue (Q3 / matrix Q10).

### 2026-11-21: Phase 2 fix #2, every coach could read studio pay rates (/crew db + app)

**Done & verified**
- Contract `contracts/fix-2-rates/CONTRACT.md` v2 (frozen by Claude as Aaron's IT, technical
  only) + `fixture.json` + checker's `attack-list.md`. Mechanism: column privileges on studios
  (no data moved); release 0009 → app → 0010.
- DB half, `crew/fix-2-pay-rates` 248f8f0 (on crew/fix-1-private-details): 0009 functions
  (`studio_pay_settings`, `studio_default_splits`, `studio_pt_default_pct`, pt_guard reads via
  helper; exempt roles read directly), 0010 revoke/grant 21 non-pay columns + DO-block self
  check, both one transaction and re-runnable; `90_fix2_pay_rates.sql` 363 checks (283 fail on
  base); 70 #2 pins flipped (c_pin ['#3=7'], cover-rule tag closed); run.sh --stop-after /
  --no-tests / --extra. 15 mutants caught; UTC + KL; R-11 (0009 only), R-12 (rollback), re-run
  ACL md5 identical. bft-checker PASS round 3 (05:21 UTC), reviewer nothing blocking.
- App half, `crew/fix-2-app-rates` d17f3eb (on crew/fix-1-app-people): 4 screens via the RPCs;
  `src/lib/studio-pay.ts`, `src/lib/studio-save.ts` (real save path, tested); unloaded rates
  never overwritten; empty % refused (settings, createChallenge, reviewPt); select guard test.
  102 node tests, tsc/eslint/build 0. bft-checker PASS round 3, reviewer re-review nothing
  blocking.
- Hosted demo check (Claude, 21 Nov ~13:30 +08, scratchpad `demo-attack2.mjs`,
  `demo2-before/after0009/after0010.txt`): before, coach Ben read 80/60 and filtered on rates;
  after 0009 nothing changed and functions answered correctly; after 0010 coach/manager/owner
  direct reads, `*`, filters, orders, embeds → 42501; Owner/Finance via function OK; Owner
  update (return=minimal) and insert `.select('id')` OK through real PostgREST (A-29/A-31);
  PT stamping OK. UI (in-app browser): owner settings page shows SBJ 75/55/support/40/60, save
  of call time left rates untouched; "Pay rates not set" banner appears for a blank rate;
  manager PT header "60% coach / 40% studio", Challenge prefill 40%, other studio redirects;
  coach shifts/slots/PT load. Demo now runs `.crew-wt/fix-2-app` with 0008–0010.

**Done but unverified**
- pg_graphql (not enabled on the demo project) and Realtime (studios not in the publication on
  the demo) not exercised on hosted; column privileges apply to both. Phone-width rendering of
  the 4 screens not checked (only text lines changed).

**Needs your approval**
- Push `crew/fix-2-pay-rates` + `crew/fix-2-app-rates`, PRs 5–6 (drafts in
  prep/phase1-pull-requests.md), after PRs 1–4, once Kelvin gives write access.
- Kelvin runs 0009, then the app deploys, then he runs 0010 (rollback line in the PR).
- Send Kelvin question 18 (managers see their studio's default PT/Challenge %); Q3 reworded to
  include the challenge % coaches see.

**Open**
- Coaches in a challenge still see that challenge's coach % and revenue (challenges_read, 0005)
  — Kelvin's Q3.
- A coach can read their own studio's PT default % via `studio_pt_default_pct` (same number as
  on their own PT sessions) — accepted in contract D8.
- `pt_update` policy has no membership check on a changed studio_id; only the null default
  blocks the move (pinned by tests K08). Harden in a later fix.
- Every new studios column now needs a `grant select`; fix #3 (QR token, same table) must keep
  the grant list in step.

### 2026-11-20: Phase 2 fix #1, managers reaching anyone's private details (/crew db + app)

**Done & verified**
- DB half, `crew/fix-1-private-details` 21fc26f (on crew/access-matrix): migration 0008 +
  `80_fix1_private_details.sql` (132 checks) + #1 pins flipped in 70. Managers: no direct
  insert/delete of memberships; update only is_lead/active, not own rows, not org-role people
  (policy + security-invoker guard trigger firing before the lead stamp); inactive members'
  contacts/notes hidden (can_manage_person + contacts_read active-only); resume_booking refuses
  self/org-role/no-row targets; only Owner/GM change or move a contact email. bft-checker PASS
  round 3 (21:30 +08; own harness 152 checks), reviewer nothing blocking. 80 fails 60/132 on
  base, 70 fails exactly the 18 #1 cells; 9 mutants caught; UTC + KL pass.
- App half, `crew/fix-1-app-people` de28999: savePerson rules in `src/lib/people-policy.ts`
  (46 node:test tests, fail-first 15/26 → 17/41 → 5/46 per round), people page gated by the
  same rule. Managers can attach only people who already coach at their studios; no
  self-add; no detail/notes overwrite of existing people; no email change on edit; exact email
  lookup; invite returning an existing account treated as existing; half-finished invite
  retryable. bft-checker PASS round 3 (21:29 +08), reviewer nothing blocking. tsc/eslint/build 0.
- Hosted check on the demo project (Claude, ~21:40 +08, script in session scratchpad
  `demo-attack.mjs`): BEFORE 0008 the manager (Mei Ling) planted the Owner, read the Owner's
  phone, repointed Ben's row to the Owner and changed her own login email; AFTER 0008 all
  refused (42501 RLS / members-guard / email-guard, P0001 resume_booking), while setLead and a
  coach phone edit still work. Demo state cleaned afterwards.
- UI on the demo with the fixed app (in-app browser): Mei Ling adding owner@, emma@ (Subang),
  her own email (mixed case) → the three refusal messages; DB shows no rows written; /people
  for a former coach redirects, for Aisha opens; Owner still opens former coach.
- Demo now runs the fixed app (`.crew-wt/fix-1-app`) and has 0008 applied.

**Done but unverified**
- Real GoTrue invite cases (re-invite of an unconfirmed existing account; brand-new invite —
  the demo's default SMTP can't send to @example.com) not exercised. Owner/GM add/edit
  regression only spot-checked.

**Needs your approval**
- Push `crew/fix-1-private-details` + `crew/fix-1-app-people` and open PRs 3–4 (drafts in
  prep/phase1-pull-requests.md) once Kelvin gives write access. They stack on PRs 1–2.
- 0008 has to be run in Kelvin's Supabase by him (or us with his written OK), after PR 4 deploys.
- Send Kelvin question 17 (shared coaches now added by Owner/GM only) with the others.

**Open**
- B1 (accepted limit): a manager can "claim" a blank account the Owner invited but hasn't given
  a studio/role yet, overwriting the Owner-typed phone/address (looks the same as a
  half-finished manager invite).
- Invite email is sent before the existing-account check (a refused manager action can re-send
  an invite to an unconfirmed person). Edit form still requires a valid email for managers.
- The app's Resume booking button (`src/app/manage/verify-actions.ts:64`) ignores the RPC error,
  so the new refusals show nothing on screen; setLead/setMemberActive likewise silently do
  nothing on refused rows. Small app follow-up.
- Managers can still reactivate a former coach of their own studio and then see them again
  (by design). Deactivation keeps Lead status (unchanged).
- anon can execute resume_booking (default grant; always refused inside). Tidy-up later.

### 2026-11-20: Demo copy of Coach Hub with fake data (Aaron can now see the app)

**Done & verified**
- Aaron's own free Supabase project `coach-hub-demo` (ref muczjyfeduajeupcbmfo, Singapore,
  org "Coach Hub Demo"; Aaron signed up via GitHub, CLI logged in on this Mac). Kelvin's 7
  migrations applied cleanly; his real email/phone/company from migration 2 replaced with demo
  values. 13 fake @example.com accounts, 285 classes (14 days back, 21 ahead), 350 filled /
  220 open positions, attendance, 2 no-shows, challenge, PT, review, notes, notifications.
- App runs from `app/` (Kelvin's main, c1dae4e, unchanged) on localhost:3000 with a
  git-ignored `.env.local` marked DEMO COPY ONLY; "sign in as" page on localhost:3001
  (127.0.0.1 only, one-time links via the admin API, no emails).
- Clicked through by Claude in the in-app browser at ~19:45Z: owner (admin, people list),
  Mei Ling (manager menu), Suresh (Faiz's absence to review), Ben (timetable, my shifts,
  no-show prompt), Aisha (extra earnings RM 3,750), Farah (finance admin), Hafiz (turned
  away as inactive). No server errors.
- Everything in `demo/` (README has restart steps). Not committed.

**Done but unverified**
- Not every screen clicked (e.g. QR check-in, claiming, PT approval, file upload of absence
  evidence). Aaron's walk-through will cover these.

**Needs your approval**
- none (the demo is ours; nothing pushed, nothing sent to Kelvin).

**Open**
- Free Supabase projects pause after ~7 days unused: restore from the dashboard.
- Demo dates are fixed around 20 Nov; reseed when they go stale.
- Corrected the inactive-person wording (Kelvin question 12): screens block them, the
  database does not.

---

## Logged live

### 2026-11-20: Phase 1 safety net, /crew db lane (test dates + access test)

**Done & verified**
- `crew/test-dates` (`b59ca81`, local commit on c1dae4e): Kelvin's tests use a week 4–10
  days ahead of today's KL date instead of 28 Sep; the KL→UTC check now catches a missing
  conversion under any session zone (it was blind under KL); 50's 5 refusals assert exact
  messages; 60 passes when KL midnight falls between its classes (it failed ~22:25–23:40 KL
  nightly); run.sh takes a restricted DB name and pins PGTZ=UTC. Tests only; migrations diff
  empty. Checker PASS 17:13:52Z (14/15 attacks; sweeps at month/year ends, leap days, every
  minute around KL midnight, 4 session zones; refusal and time-zone mutants now fail, passed
  on main). Code review: nothing blocking. Round 2 comment-only, confirmed by grep; full
  suite re-run by orchestrator 17:15:45Z.
- `crew/access-matrix` (`caea2a5`, on top of b59ca81): new `supabase/tests/70_access_matrix.sql`
  (1336 lines). Read access for 18 roles × 21 relations + 40 sensitive columns = 1098 cells,
  exact row sets, own fake seed, whole file rolled back, refuses non-test DB names. Pins
  audit #1 (read half, 18 rows), #2 (rates, 44), #3 (check-in token, 7); literal anchors
  catch a deleted/moved count. Uncovered table/view/column fails. Three rounds: checker FAIL
  → PASS → PASS (final 01:46 +08 / 17:46Z); code review nothing blocking (final). Full
  run.sh with 70 re-run by orchestrator: all pass, 17:47:18Z.
- Kelvin-facing questions on who sees what: `prep/access-questions-for-kelvin.md` (16 items +
  mapping to test tags). PR drafts: `prep/phase1-pull-requests.md`.

**Done but unverified**
- Anything on real Supabase: `auth.uid()` reading `request.jwt.claims`, storage bucket
  `absence-evidence`, PostgREST column exposure. No staging yet: CANNOT VERIFY.
- Role-creation race in run.sh on a brand-new cluster (C1-A14): needs a fresh cluster.

**Needs your approval**
- Push both `crew/*` branches to Kelvin's GitHub and open the 2 PRs (texts ready in
  `prep/phase1-pull-requests.md`). Tests only, no app or database change. Rollback: close the
  PR and delete the branch. Never `main`.
- Send Kelvin the who-sees-what questions (with the pay questions). 1, 2, 3 and 12 are needed
  before Stage 3.

**Open**
- Found by the matrix: a person set to **inactive** (profiles.active=false) still reads
  their studio's data, including rates and the check-in token (`open:inactive-profile`; repro:
  70's `inp`/`xgm` cells). Candidate Phase 2 fix, pending Kelvin's Q12. (Checked in the demo
  on 20 Nov: the screens do block them, `session.ts` redirects to `/login?error=inactive`;
  the gap is the database, reachable directly with their still-valid sign-in token.)
- Write access (insert/update/delete per role, direct write vs RPC) not tested yet: needed
  to pin audit #1 write path, #4–#6, #8–#13. Next PR, with Phase 2.
- 60 verifies a class that hasn't happened yet; this only works because of audit #4. When #4
  is fixed, 60 must change.
- 37 security definer functions are executable by anon (e.g. `fmt_class` returns a class
  label to a signed-out caller). Overlaps audit "helper functions answering anyone".
- Matrix maintenance nits (not done, low risk): leak anchors are counts, so a marker moved
  between cells with two matching edits passes (checker A1/A2); `absences.manager_note` could
  be `explicit`; header repeats anchor numbers; `c_cells` is derivable.
- run.sh allows any `crew_*` name, so a run named after another lane's DB would drop it.
- Test DB is not permanent: the server stops on reboot and its data folder is in the
  session scratchpad. To recreate: `initdb -D <dir> -U postgres --auth=trust` then
  `pg_ctl -D <dir> -o "-p 54329 -k /tmp/pg -c listen_addresses=''" start` (Postgres.app 17 bin).
- Worktrees `.crew-wt/test-dates` and `.crew-wt/access-matrix` kept until the PRs are merged.

### 2026-11-20: Marketing switched to pay-per-close (plan drafted)

**Done & verified**
- Pay-per-close plan written: `prep/marketing/pay-per-close-strategy.md`. Recommended deal
  (15% of member revenue for 12 months, no monthly fee, nothing on the RM130 trial), win-back and retention plans, the
  sales-team cap (~20 new members/month at 10% conversion), risks and questions for Kelvin.
- Income model `prep/marketing/pay-per-close-model.py`, on real prices (RM130/week = RM563
  a month): base case RM228k over 18 months vs RM126k for the old RM7k/month package. Passes
  RM7k in month 4. Weak case passes it only in month 9 (20 Nov).
- Aaron confirmed: revenue share, not profit share (20 Nov).

**Done but unverified**
- Prices are from BFT's site (RM130 trial; RM130/week or RM260/fortnight, no lock-in,
  10-week freeze). Promo discounts, cancellation rates (6% / 5% a month) and win-back
  volume are assumptions. Needs Kelvin's real figures.

**Needs your approval**
- Rate 15% or 20%. Trials not charged (recommended). One-off setup fee or none.
  Keep Coach Hub's RM25 separate (recommended).
- Then rewrite the Kelvin-facing proposal (section 7, pricing) to match.

**Open**
- The 18 Nov proposal Kelvin has says the RM25 covers marketing too, with "no extra
  performance fee". The new version must address that plainly.

### 2026-11-20: Kick-off sent, new Mac set up (waiting on Kelvin)

**Done & verified**
- This project cloned to `/Users/aaron/Documents/BFT Project` on a new Mac (19 Nov).
- Kelvin's repo cloned into `app/`: `main` only, 9 commits, last `c1dae4e` 26 Sep, migrations
  0001–0007. Same as the audit saw, so nothing pushed since (checked 19 Nov).
- GitHub CLI installed and signed in by Aaron.
- Node 26.13.1 LTS in `~/.local/node` (checksum verified) and Postgres.app 2.9.7 / PG 17.12
  in `/Applications` (signature notarized), with Aaron's OK, 20 Nov. No Homebrew needed.
- Throwaway test DB on socket `/tmp/pg`, port 54329, data in the session scratchpad.
  Kelvin's SQL tests: all pass up to `50_claiming`, which fails on its fixed Sept dates, same
  as the 14 Nov audit (20 Nov).
- `app/`: `npm ci`, `next build` (dummy env vars), `tsc --noEmit` and `eslint` all pass (20 Nov).

**Done but unverified**
- Kick-off WhatsApp sent to Kelvin (per Aaron, by 20 Nov): Supabase Pro, Supabase + Vercel
  invites, branch protection on `main`, migrations 6–7, unpushed changes. No reply yet.

**Needs your approval**
- Agreement: being drafted by our finance team, not by this project.
- Pay questions (Q-1…Q-9 in `prep/stage3-pay-spec.md`) to send Kelvin in a few days.

**Open**
- `audit-kit/build.sh` still points at the old Mac's paths (`/Users/aaron/dev/...`,
  Homebrew Postgres). Update before reusing it.
- Node is not on the shell PATH; use `~/.local/node/bin`. Postgres tools are in
  `/Applications/Postgres.app/Contents/Versions/17/bin`.
- Supabase Pro not on yet. No fix goes live until it is.

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

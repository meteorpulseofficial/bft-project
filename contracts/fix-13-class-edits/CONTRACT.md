# Fix #13 (managers edit classes directly, skipping checks and notices): contract

**Version:** 3 · **Frozen:** not yet (awaiting Aaron) · **Owner:** db lane (no app change required) ·
**Last changed:** 2026-11-25 · by the db lane (v3: round 2, checker finding 1 and E8–E10)

## What changes (for Kelvin)

Until now a manager (and the Owner/GM) could write straight to the class and position tables through
the app's database connection: move a class's start time, change the headcount, cancel or un-cancel
it, change its type, studio, length or "special event" flag, add or delete classes and positions.
None of the app's checks ran and no coach was told. Moving a class could also be used to wash away a
no-show or a late check-in.

After this fix:
- **Nobody can write the class or position tables directly through the app connection** — managers,
  the Owner and the GM included. Everything goes through the app's buttons, which already use the
  safe functions: Assign / claim / drop / swap, change class type, cancel / un-cancel, verify (which
  sets the headcount) and "publish the timetable" (which creates classes). Start time, length,
  special event and studio can't be changed through the app for now (Q-B, Q-C). For a correction
  today, the Owner/GM asks for it to be done in the database console (SQL editor).
- **A no-show can't be deleted away.** A class or position that has a no-show on record can't be
  deleted by anyone: "This class has a no-show on record and can't be deleted. Cancel it instead."
  (Q-D, Q-E). This also means a studio with a no-show on record can't be deleted.
- **A position that has attendance or a no-show keeps its coach and can't be removed.** Unassigning
  or reassigning it, a swap, claiming or dropping it are refused for everyone: "This position has
  attendance or a no-show recorded, so its coach can't be changed." Deleting it is refused too
  ("... so it can't be removed."); changing a class's type keeps such a position and trims only the
  other empty ones. Deleting a whole class without a no-show still takes its attendance with it. (A check-in that was scanned but not yet verified does not
  count: unassigning still works there, as today.) This closes the trick where a no-show was moved to
  another coach and then "corrected" away, and the one where the next coach's real no-show recorded
  nothing.
- **Managers can only publish the timetable from today onwards** (in the studio's time zone):
  "Classes can only be generated from today onwards." The app already starts from today. The Owner
  and GM may still fill in past days.
- Nobody but the database owner (SQL editor, restores) can empty a whole table (a command that
  bypasses all row rules); the classes, positions, attendance, no-show and correction tables refuse
  it even for the server key: "This table can't be emptied." 

Existing data is not changed. The migration prints how many classes and positions are already in an
odd state (see E6).

## Today's paths (base afbaaee, 0001–0018)

- Grants: the Supabase defaults give anon and authenticated ALL (incl. INSERT, UPDATE, DELETE,
  TRUNCATE) on every public table (`00_supabase_stub.sql` mirrors this). TRUNCATE ignores RLS.
- `classes_write` / `positions_write` RLS policies (FOR ALL, `manages_studio(...)`) let any manager of
  the studio, and the Owner/GM, write any column directly.
- 0013 guards (`classes_guard_lock`, `positions_guard_lock`): only verified classes and the verified
  stamp are protected; Owner/GM, postgres, service_role exempt.
- 0014 guards (`positions_guard_write`, `classes_guard_studio`): managers may not change who coaches
  a position or move a class with coaches to another studio; may insert empty positions, change seq,
  delete empty positions, delete classes, change every other class column.
- `absences.position_id → positions(id) ON DELETE CASCADE`: deleting a class or position deletes its
  no-shows (strikes) with no record (N2).
- `assign_position(pos, NULL)` works after the class started and keeps the absence on an empty
  position (H12); `assign_position(pos, other)` on a moved class hands a no-show position to another
  coach (launder_back, transfer/N1). `do_swap`, `claim_position`, `drop_position` have no check for
  attendance or absences either.
- `generate_classes` accepts any date range up to 92 days, past included (G1).
- The app (`src/`) makes no direct writes to classes, positions, attendance or absences; it reads
  `classes` / `positions` and calls the functions. `generateWeeks` passes `todayIn()` (today's date in
  Kuala Lumpur) as `p_from`.

## Decisions (orchestrator, final for this round)

- E1 Main wall: revoke INSERT, UPDATE, DELETE, TRUNCATE on public.classes and public.positions from
  anon, authenticated and PUBLIC. Owner/GM lose raw API edits too (changes fix #4's D1/R09); their
  corrections go through the SQL editor (postgres) until Kelvin asks for RPCs. service_role keeps
  direct writes. Keep the 0013/0014 triggers and the RLS write policies as a second wall. Also revoke
  TRUNCATE (only TRUNCATE) from anon/authenticated/PUBLIC on attendance, absences,
  absence_corrections, swaps and every other public table where the defaults grant it.
- E2 `absences.position_id` FK: ON DELETE CASCADE → RESTRICT. Deleting a class or position that holds
  an absence fails for everyone, postgres included, with a clear message raised first. attendance
  keeps CASCADE. set_class_type's delete of empty positions works without an absence and fails closed
  (clear message) with one.
- E3 assign_position refuses to change the coach (including to NULL) on a position that has an
  absence row or a non-pending attendance row, for everyone: "This position has attendance or a
  no-show recorded. Correct the attendance first." (text replaced by E9) Close every other path that can change
  positions.coach_id or delete a position the same way. Keep D12 in set_attendance.
- E4 No new class-edit / move / insert RPC this round. Kelvin questions: Q-A..Q-E (below).
- E5 generate_classes refuses a p_from before today in the studio's time zone: "Classes can only be
  generated from today onwards." Same signature.
- E5b (v2) The E5 refusal applies only to callers who are not is_admin(): the Owner/GM may generate
  past ranges (back-fill; trusted, and they have the SQL editor anyway). ops/seed/data.sql and
  demo/seed.sql, which set an owner JWT, pass unchanged; neither is edited.
- E8 (round 2) set_class_type skips (keeps) any position with an absence or non-pending attendance
  when trimming, still changes the type and trims the others; it never deletes such a position and
  never fails because of one. Checker finding 1 (round 2): deleting a position with an absence OR
  non-pending attendance is refused for everyone (E3); deleting a whole class keeps attendance
  CASCADE (E2).
- E9 (round 2) The coach-change text is "This position has attendance or a no-show recorded, so its
  coach can't be changed." (the old "Correct the attendance first." named a step that doesn't exist).
- E10 (round 2) BEFORE TRUNCATE statement trigger on classes, positions, attendance, absences and
  absence_corrections; refused unless current_user is postgres or supabase_admin (service_role
  refused): "This table can't be emptied."
- E6 Existing rows left alone; the result line counts classes whose starts_at differs from their
  absences' class_starts_at, positions whose absence owner differs from the current coach, and past
  classes created after their start.
- E7 Re-run safety and house style (one transaction, precondition naming 0018's marks, end checks,
  re-runnable with the same line, 0016/0017 still refused, check_in untouched, no invoker function
  reading studios, a 0019 baseline line).

## Owner's technical choices (db lane; the orchestrator may overrule)

- T1 **E2/E3 as triggers, not function edits.** One trigger function `guard_position_record`
  (BEFORE UPDATE OR DELETE on positions) and `guard_class_record` (BEFORE DELETE on classes). The
  UPDATE branch refuses a change of coach_id, class_id or id when the position has an absence or an
  attendance row with status ≠ 'pending'; the DELETE branch refuses when it has an absence, or
  non-pending attendance while its class still exists (when the whole class is deleted the class
  row is already gone as the positions cascade, so attendance keeps CASCADE, E2). set_class_type
  is the one function re-created (E8, from 0013's body with the skip added); re-running 0013 would
  bring back its old body, which then fails closed on a blocked position instead of skipping it. This
  covers assign_position, claim_position, drop_position, do_swap (respond_swap / decide_swap),
  set_class_type, raw service_role / postgres writes and any future function, and it is not undone
  by re-running 0006/0007/0013/0014 (which re-create those function bodies). No existing function
  body is changed except generate_classes. Applies to everyone (no current_user exemption), as E2/E3
  say.
- T2 Messages (all P0001): class delete "This class has a no-show on record and can't be deleted.
  Cancel it instead."; position delete "This position has attendance or a no-show recorded, so it
  can't be removed."; coach change "This position has attendance or a no-show recorded, so its
  coach can't be changed."; truncate "This table can't be emptied."; generate_classes "Classes can only be generated from
  today onwards.". Raw API writes now get Postgres's 42501 "permission denied for table classes" /
  "... positions" before any guard (0013's "A class is marked verified only through Verify" and
  "This class is verified and locked. Only the Owner or GM can change it." are no longer reached
  through the API; A-05). With the guards off, the foreign key itself refuses with 23503 "update or
  delete on table "positions" violates foreign key constraint "absences_position_id_fkey" on table
  "absences"" (Postgres 17 reports RESTRICT with that text).
- T3b `guard_truncate()` is security INVOKER on purpose (it must see the caller as current_user);
  it reads no table, EXECUTE revoked from PUBLIC/anon/authenticated. Restores and the seed run as
  postgres and are unaffected (ops kit restore / seed tests pass).
- T3 Guard functions are SECURITY DEFINER (search_path = public) so they see every absence and
  attendance row whatever the caller's RLS view (fail closed). They can only run as triggers
  (Postgres refuses a direct call), EXECUTE is revoked from PUBLIC/anon/authenticated, and they never
  name studios.
- T4 TRUNCATE is revoked from anon/authenticated/PUBLIC on every table, view and foreign table in
  public (21 at 0018: absences, attendance, bootstrap_owners, challenge_coaches, challenges,
  check_ins, class_types, classes, coach_reviews, companies, extra_earnings (view), notifications,
  positions, profile_contacts, profile_notes, profiles, pt_sessions, studio_members, studios,
  swap_requests, template_slots; absence_corrections already had none). Also
  `alter default privileges in schema public revoke truncate on tables from public, anon,
  authenticated` for the role running the migration (postgres on Supabase), so a later table does
  not get it back. service_role keeps TRUNCATE.
- T5 The FK swap runs only when the constraint is not already RESTRICT under its usual name (so a
  re-run does nothing); it is re-added as `absences_position_id_fkey ... on delete restrict`
  (validated against existing rows, which the old FK already guaranteed).
- T6 generate_classes: the date check comes after its existing role, range and studio checks
  (`p_from < (now() at time zone <studio tz>)::date and not public.is_admin()`; an inactive GM is not
  is_admin(): with no active manager row they get the existing role refusal, with one they get the
  manager rule). Same signature, definer, search_path, grants.
- T7 Not changed (recorded): set_attendance / verify_class / check_in / report_present /
  set_class_cancelled / set_class_type / assign_position etc. bodies; the 0013/0014 triggers and the
  write policies; service_role's direct writes (it is still bound by T1's guards).

## Consequences to know (recorded, not decided by the db lane)

- **Today's earlier slots:** generate_classes from today still creates today's slots whose time has
  passed (they start in the past, unclaimable). Unchanged.
- **Seeds:** ops/seed/data.sql l.78 and demo/seed.sql l.90 generate two weeks of past classes with an
  owner JWT; under v1's E5 they were refused (14 ops kit tests failed). E5b lets them through
  unchanged.
- **Staging check (cannot be tested locally):** if a public table is owned by a role other than the
  one running 0019 (e.g. supabase_admin on real Supabase), the revokes and the default-privilege
  change may not take effect on it. The end checks then abort the whole file (nothing kept) with a
  message naming the table, its owner and the role running the file. Kelvin's staging run tells us.
- **Re-runs:** re-running 0013 after 0019 still restores 0013's set_attendance (unsafe since 0017,
  as recorded there); re-running 0001 would restore generate_classes without the date check. The
  ops/migrate.sh ledger never re-runs an applied file.

## Acceptance tests (where)

- `supabase/tests/99d_fix13_class_edits.sql` — 164 checks (v2: A11 Owner / GM back-fill, inactive GM;
  v3: position delete with attended / late / no_show attendance refused, pending allowed, whole-class
  delete keeps CASCADE, set_class_type skips blocked positions, TRUNCATE guards, C03b/C10): A-01..A-28 (A-17..A-20 both "as is" and
  with the class moved by postgres, so the reassignment is judged on its own), W-* (second wall:
  with the pre-0019 grants put back inside a check, the 0013/0014 guards and the 0019 guards still
  refuse; E3 for service_role; GM still passes the fix #4 lock in decide_swap), C-* catalog. On base
  (afbaaee) most fail (104 of the v2 150); on the round-1 0019, 33 of the v3 164 fail; the 43 that pass there are controls (the functions that must keep
  working, service_role writes, the 0013/0014 guards that already existed).
- `supabase/tests/scenarios/fix13_apply.sh` — A-29, A-30, A-32: result line on seeded odd rows,
  rows unchanged, re-run identical, 10/12 after 19 no change, 16/17 refused, 13/14 after 19 keep
  E1–E3, precondition at 0017, baseline line false → true and every baseline line true at 0019.
- Existing tests changed because of the new behaviour (each keeps its protection proven):
  - `10_stage1.sql` l.99 coach raw update of classes: "0 rows" → permission denied.
  - `50_claiming.sql` l.54 coach raw update of positions: "0 rows" → permission denied (and coach
    unchanged).
  - `96_fix4_verified_lock.sql`: restores the pre-0019 grants inside its transaction so R-08 / R-09 /
    K keep testing the 0013 guards; A21-assign-own and A22-decide-gm (pV1 is attended) now expect the
    E3 refusal with nothing changed; R09-svc-pos moved to an empty position; A21-assign-own-pending
    added (Owner still passes the lock); C01-triggers lists the two new triggers. Anchor 223 → 224.
  - `97_fix5_lead_positions.sql`: restores the pre-0019 grants inside its transaction (0014 guard
    rules stay tested); D7-gm-locked-eligible (vL has attendance) expects the E3 refusal;
    R08-gm-lead-bad clears vL's attendance first so it still tests the Lead rule; REC-A30-cancel runs
    without the grants and now records the fix (denied, class stays scheduled); C01-triggers.
  - `97` R08-own-delete (round 2): deletes vS filled by its before-step; vL has attendance and can no
    longer be deleted (99d A-15). `96` R09-mgr-open-headcount / -delete texts updated.
  - `99b` C05-trigger (round 2): lists absences_guard_truncate.
  - `99b_fix9_strike_window.sql`: A08-later-mgr, A08-later-in-window, A09-earlier-mgr,
    A10-verified-owner move the class as service_role (fix #9's stored start still proven; a
    manager's move is refused, 99d A-21/A-24); A09-earlier-own-strike stays the manager and now
    expects permission denied with the strike kept.
  - `99c_fix10_noshow_correction.sql`: launder() and R2-owner-differs-repro build the "owner is not
    the current coach" state directly (postgres) instead of through assign_position (now refused), so
    D12 / D4 stay tested on rows already in that state; A16-unassign expects the E3 refusal (coach,
    attendance, absence, strike unchanged); R3-launder-noshow (N1) text notes it is an existing-row
    case now.
- `ops/baseline-checks.tsv` — line for 20260928000019.

## What must NOT change

Strike rules (fixes #8/#9/#10), set_attendance and its texts (0016/0017 stay refused), verify_class,
check_in (oid kept), claim / drop / assign / swap rules for positions without a record, fix #4 lock
and texts (still raised by the guards and functions), fix #5 eligibility rules, every earlier test and
scenario (changed lines listed above).

## Open (for Kelvin, via the orchestrator)

- Q-A Walk-in substitute after the class started: should a manager be able to put the coach who
  really taught into a position that already has attendance (and if so, what happens to the old
  coach's record)? Today: SQL editor only. Whether the Owner/GM get a correction RPC for this (change
  the coach of a position that has attendance, with a record kept) is a Kelvin decision. Related: once a position's attendance is attended / late /
  no_show its coach can't change at all through the app. Correcting the attendance can remove a
  no-show (set_attendance to attended / late, fix #10), but attendance never goes back to pending, so
  a wrong coach on a started class can only be fixed in the SQL editor (delete the attendance row,
  then reassign).
- Q-B Who may move a class's time (manager / Owner / GM), up to when, and are the coaches notified?
  Today: nobody through the app.
- Q-C Who may flag a class as a special event (it pays the event rate)? Today: nobody through the app.
- Q-D Is deleting a class (or a studio) ever allowed? Today: only without any no-show on record, and
  only from the server or the SQL editor. Deleting a studio that has any no-show on record now fails
  too (the delete cascades to its classes and meets E2).
- Q-E Cancelling a class after a no-show keeps the no-show and its strike (set_class_cancelled does
  not touch absences). Should it?
- App note (bft-builder, no change now): the app passes today's date in Kuala Lumpur to
  generate_classes (`todayIn()` with the default zone). For a studio east of KL (none today) a
  manager's "Publish" would be refused for the first hour(s) after that studio's midnight;
  `todayIn(studio timezone)` would remove that. No effect on KL studios.
- Also: should Owner/GM get correction RPCs (move, headcount fix outside verify, special event) now
  that raw edits are closed?

## Release order

No app change is needed: the app does no direct writes to these tables. If the app ever offered
"delete class" or raw edits, they now get permission errors. Run 0019 after 0018.

## History

- v1 2026-11-25: written by the db lane from E1–E7 and the checker's attack list (A-01..A-32).
- v3 2026-11-25: round 2. Checker finding 1 (a position with attended / late attendance could be
  deleted, also through set_class_type on old data): delete refused for everyone unless the whole
  class is deleted. E8 set_class_type skips blocked positions. E9 new coach-change text. E10
  TRUNCATE guards. End-check messages name table, owner and role (staging check). Shape change for
  the app: refusal texts only.
- v2 2026-11-25: E5b (orchestrator): Owner/GM may generate past ranges; seeds pass unchanged. The
  frozen-coach, studio-delete and app-date notes moved under Open (Q-A, Q-D, app note). Shape change
  for the app: none (one refusal no longer applies to Owner/GM).

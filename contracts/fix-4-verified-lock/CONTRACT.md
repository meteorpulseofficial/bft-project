# Fix #4 (verified classes are not locked): contract

**Version:** 2 · **Owner:** the db lane · **Last changed:** 2026-11-21 · **Frozen:** v2, 2026-11-21,
by Claude as Aaron's IT (technical calls delegated; product questions to Kelvin)

## What changes (for Kelvin)

Your plan says verified classes lock and flow into invoices. Today a manager can still change
attendance after verifying (we turned "attended" into "no-show"), can set attendance on cancelled
classes and on classes that haven't happened yet, and a future "no-show" opens an absence that can
become a strike. After this fix: once a class is verified, a studio manager can't change its
attendance, its coaches or its details; attendance can only be set on classes that have started
and weren't cancelled. You and the GM can still correct a verified class (question 20).

## Today's paths (from the code)

- Attendance writes go only through security-definer functions (`set_attendance`, `verify_class`,
  `check_in`, `report_present`); there are no direct write policies on `attendance`/`absences`.
- `set_attendance` (0007:429) checks only `manages_studio`; no check on class status, start time
  or `classes.verified_at`. A `no_show` inserts an absence + notification.
- `classes_write` (0001:406) and `positions_write` let a studio manager change any class/position
  row directly, including `classes.verified_at`, `status`, `starts_at`, and the coach of a
  position, verified or not.

## Decisions (orchestrator, final for v1)

- D1. **Lock rule:** a class is locked when `classes.verified_at is not null`.
- D2. `set_attendance`: refuse (errcode 42501 for not allowed, P0001 with a clear message for the
  rules below), changing nothing, when: the class is cancelled (`status <> 'scheduled'` — db lane
  confirms the status values); the class has not started (`now() < starts_at`); the class is locked
  and the caller is not Owner/GM (`is_admin()`). Owner/GM may correct a locked class; the class
  stays verified.
- D3. `verify_class`: refuse on a cancelled class and on a class that hasn't started; on an
  already-verified class, a manager gets a clear "already verified" refusal (no re-stamp).
- D4. `check_in` and `report_present`: must never write to a locked class's attendance (today they
  skip rows whose own `attendance.verified_at` is set — make sure a locked class with no attendance
  row for a position, or a row that is still pending, is also skipped).
- D5. **Direct table writes** (guard triggers, security invoker, same pattern as fix #1): for a
  non-admin caller, refuse any UPDATE/DELETE of a locked `classes` row, any change of
  `classes.verified_at` / `verified_by` outside `verify_class`, and any INSERT/UPDATE/DELETE of
  `positions` belonging to a locked class. Exempt postgres / service_role / supabase_admin and
  `is_admin()`. Unverified classes keep today's direct-edit behaviour (that is audit #13, a later
  fix) — only the lock is in scope.
- D6. A future/cancelled no-show can no longer be created, so no absence/strike from it. Existing
  absences are untouched (correcting a no-show's strike is audit #10, a later fix).
- D7. App: the verify page shows a verified class as locked (no change buttons) for managers;
  Owner/GM still see the controls; refusals are shown (the action already returns the DB message).
- D8. Migration 0013, one transaction, re-runnable; must keep fix #1–#3 guarantees, tests and
  scenarios passing.

## v2 decisions (after the checker's pre-mortem, `attack-list.md`)

- D9 (S-1). Guard triggers can't see security-definer functions (they run as postgres), so
  **every definer function that changes a locked class must check the lock itself**: one helper
  (e.g. `assert_class_unlocked(class)`) raising P0001 "This class is verified and locked." for
  non-admins, called by `set_attendance`, `verify_class`, `assign_position` (incl. NULL),
  `decide_swap`/`do_swap`, `request_swap`/`respond_swap`, `claim_position`, `drop_position`,
  `set_class_cancelled` (cancel and uncancel), `set_class_type`, `report_present`. Owner/GM pass.
  `submit_absence` / `decide_absence` must keep working on locked classes (don't over-lock).
- D10 (S-4). Error codes: role not allowed → 42501, checked **first** so a refusal never reveals
  a class's state; lock / cancelled / not-started rules in functions → P0001 with a clear message;
  direct table writes on a locked class → 42501 (guard trigger).
- D11 (S-5). `check_in`: locked classes are skipped entirely — never picked as the first class
  (lateness then counts from the next open class), never written, never listed in `covered`; they
  still count for run continuity (v_prev_end advances past them). `report_present` on a locked
  class → P0001 "This class is already verified. Speak to your manager."; on a cancelled class →
  P0001 "This class was cancelled."
- D12 (S-3, A-11). verify_class on a verified class: manager refused; Owner/GM may update
  headcount only, verified_at/by unchanged. Admin corrections leave no history yet (question 20
  asks Kelvin whether a record is needed before pay reads it). Admin may still clear verified_at
  directly (trusted role).
- D13 (S-6). Verifying stays allowed once the class has started (today's behaviour).
- D14 (S-2, S-7, S-8). Out of scope and recorded as open: direct starts_at/status edits on
  unverified classes (audit #13), cancelling after a no-show leaving the absence (audit #10),
  absence timing (#8/#9). 0013 does not rewrite existing rows; it reports in its result line how
  many existing classes are verified-but-future or verified-and-cancelled.
- D15 (A-24, A-40, A-42). App: `setDayClassType` reports which classes were refused instead of
  stopping half-way silently; `decideSwap` and `decideAbsence` show the database refusal.
- D16 (A-30, A-32). Guard triggers fail closed when the class can't be found (look it up without
  RLS inside a small definer helper), and foreign-key actions run as the owner keep working.

## Acceptance tests

- R-01 manager sets attendance on a verified class (any status) → refused, row unchanged, no new absence.
- R-02 Owner/GM corrects attendance on a verified class → allowed; class stays verified.
- R-03 set_attendance on a cancelled class → refused (manager and Owner/GM).
- R-04 set_attendance on a class that hasn't started (incl. no_show) → refused; no absence, no notification.
- R-05 set_attendance on a started, unverified, scheduled class → works as today (incl. no_show → absence).
- R-06 verify_class on cancelled / future / already-verified (manager) → refused, nothing stamped.
- R-07 check_in / report_present never change a locked class's attendance.
- R-08 manager direct UPDATE/DELETE of a verified class row, or setting/clearing `verified_at` directly,
  → refused (42501), row unchanged; same for positions of a verified class (insert/update/delete).
- R-09 Owner/GM and service_role direct edits still allowed; manager direct edits of unverified classes
  unchanged (audit #13 later).
- R-10 Kelvin's tests 10–60 and fixes #1–#3 tests/scenarios all pass; `70` unchanged unless a pin is
  about this finding.
- R-11 App: verified class shows locked for a manager, controls for Owner/GM; a refusal message shows.

## What must NOT change

Check-in by scan for today's classes, the 180-minute run, lateness maths, verify_class on a normal
class, absences/strikes for real no-shows, every earlier fix.

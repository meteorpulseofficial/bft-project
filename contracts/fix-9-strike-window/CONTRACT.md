# Fix #9 (strike window counts from marking, not the class): contract

**Version:** 2 · **Frozen:** v2, 2026-11-24, by Claude as Aaron's IT · **Owner:** db lane (+ small app half) ·
**Last changed:** 2026-11-24 · by Claude as Aaron's IT (technical calls delegated; rules to Kelvin)

## What changes (for Kelvin)

Strikes count for 90 days (each studio's "strike window"). Today those 90 days start when the
manager marks the no-show, not when the class happened — so a class from 100 days ago, marked
today, counts as a brand-new strike and can pause a coach's booking. After this fix a strike counts
for 90 days **from the class date**. The 5 days to explain still start when the no-show is marked
(a coach can't explain something they haven't been told about) — that part is question 28.

## Today's paths

- `strike_count` (re-created in 0016, line ~107): window test `a.created_at >= greatest(now() -
  strike_window_days, strikes_cleared_at)`. `absences.created_at` = when the no-show was marked.
- The class date is `classes.starts_at`, reached via `absences.position_id → positions.class_id`.
- `booking_paused` calls `strike_count`; `claim_position` checks `booking_paused`.
- `set_attendance` (0016) sets `due_at = now() + noshow_explain_days` (unchanged by this fix).
- `resume_booking` sets `studio_members.strikes_cleared_at = now()`.
- App shows "N strikes in D days pauses booking" (wording still true after the fix).

## Decisions (orchestrator, v1)

- D1. A strike is inside the window when its **class started** within the last
  `strike_window_days` (`classes.starts_at >= now() - window`). Everything else in fix #8's strike
  rule (invalid, or undecided and unanswered/late past due) is unchanged.
- D2. `strikes_cleared_at` (resume booking) keeps comparing with **when the absence was recorded**
  (`absences.created_at`): resuming forgives every strike recorded up to that moment; a no-show
  marked later still counts, even for an older class (within the window). State this in the header.
- D3. A no-show for a class older than the window is still recorded (absence row, unpaid class,
  notification) but never counts as a strike. No change to set_attendance.
- D4. The 5-day reply deadline still runs from marking (question 28). No change.
- D5. Migration 0017, one transaction, one begin/commit pair, re-runnable, applied via
  `ops/migrate.sh local` and `supabase/tests/run.sh`; baseline-checks line; result line with counts
  (strikes that stop counting; coaches whose booking pause lifts; and the reverse if any). Every
  earlier test/scenario and fix #1–#8 guarantee keeps passing (incl. 0016's late-answer rule).
- D6. If a strike's class or position can't be found (should not happen: position delete cascades
  to absences), it must fail **safe** for the coach in a documented way — owner decides and tests.

## v2 decisions (after the checker's pre-mortem, `attack-list.md`; these win over v1)

- E1 (SP-2, A-08–A-10). The class start is **stored on the absence when it is recorded**: new column
  `absences.class_starts_at timestamptz not null`, filled by a BEFORE INSERT trigger from the class
  (so set_attendance needn't change for this), backfilled for existing rows from the class's current
  start. No one can change it afterwards (absences have no direct write policies; the trigger also
  refuses updates to it except by postgres/service_role). The window counts from
  `least(class_starts_at, created_at)` — so moving a class later can't extend a strike and moving it
  earlier can't erase one.
- E2 (SP-4, A-12, A-29). One helper decides "does this absence count as a strike right now"
  (window + strikes_cleared_at + fix #8 rule); `strike_count` uses it, and the coach-facing texts
  follow it:
  - no-show notification for a class already outside the window: "…This class is outside the
    strike window, so it won't count as a strike. The class is unpaid. You can still explain by
    <deadline>." (change only that text in set_attendance; keep all fix #4/#8 behaviour);
  - submit_absence's deadline refusal and decide_absence's "invalid" notification don't promise a
    strike when the absence doesn't count (outside the window, or forgiven by a resume);
  - a read function for the app, callable by authenticated only for absences the caller can already
    see (own, or a studio they manage; else null), so the coach page and manager page label strikes
    correctly. App half uses it.
- E3 (SP-3). D2 stays (resume forgives every absence recorded up to that moment). Edges documented
  and tested: A-12 (pending at resume, decided invalid later → not a strike, and now not promised as
  one), A-13 (re-mark after resume counts again and resets the deadline — added to question 28).
  Question 31 for Kelvin: should resume forgive only strikes that existed at that moment?
- E4 (SP-5). Inner join to the class/position: an absence with no class never counts; strike_count
  never raises (claim_position depends on it). Tested with session_replication_role = replica.
- E5 (SP-6). Use `make_interval(hours => 24 * strike_window_days)` so the window doesn't depend on
  the session time zone; compare instants only.
- E6 (SP-1, SP-7). Test 99's A12-out-of-window row (recorded before its class started — impossible in
  real use) moves onto a class older than the window; any other test rows with created_at <
  starts_at likewise. Re-running 0016 after 0017 must not silently restore the old strike rule —
  0016 is the one earlier migration whose re-run is allowed to be refused by a precondition, or 0017's
  check documents the order; owner decides and tests.
- E7 (SP-4 money). Question 30 for Kelvin: should a no-show older than the strike window, or in a pay
  month already invoiced, be markable at all? Out of scope here. reliability_scores uses a fixed 90
  days, not the studio's window — recorded, unchanged.

## Acceptance tests

- R-01 class 100 days ago, no-show marked today, unanswered past due → not a strike; invalid →
  not a strike.
- R-02 class 10 days ago, marked today, invalid → strike.
- R-03 boundary: class started exactly `window` days ago vs 1 s later (transaction now()).
- R-04 studio with a 30-day window: class 40 days ago → not a strike.
- R-05 resume booking at T, then a no-show marked after T for a class before T (within window) →
  counts; a strike recorded before T → doesn't (D2).
- R-06 booking pause and claim_position follow the new count (paused → unpaused when old strikes
  drop out, and vice versa).
- R-07 fix #8 still holds: late answers count, valid decisions never count.
- R-08 full suite + scenarios + kit + re-run + result line.

## What must NOT change

The strike rule itself (what counts), the 5-day reply deadline, manager decisions, resume booking,
every earlier fix.

### v2 acceptance additions
- R-09 class moved later after marking → strike doesn't last longer; moved earlier → strike doesn't
  disappear (A-08, A-09).
- R-10 notification, submit refusal and decide notification texts don't promise a strike for
  out-of-window or forgiven absences; they still do for counting ones (A-12, A-29).
- R-11 the app read function returns the right answer to the coach and their managers, null to
  anyone else.
- R-12 session time zone (UTC, KL, New York) doesn't change the result (A-03, A-06).
- R-13 missing class → not counted, no error (A-20).
- R-14 app: coach page and manager page show "strike" only when the absence counts.

### Release order (fresh reviewer round 1)
Migration 0017 must be live **before** the app change (PR for crew/fix-9-app-strike): the app reads
`absences.class_starts_at`, which only exists after 0017. Before it, the absence pages would show
nothing. Written into the PR notes.

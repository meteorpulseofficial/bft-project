# Fix #5 (managers can put any coach into a Lead position directly): contract

**Version:** 2 · **Owner:** the db lane · **Last changed:** 2026-11-21 · **Frozen:** v2, 2026-11-21,
by Claude as Aaron's IT (technical calls delegated)

## What changes (for Kelvin)

The app's Assign button only lets a manager put a coach into a Lead spot if the coach has Lead
status at that studio. But the database underneath let a manager write straight into the
positions table and put **anyone** in a Lead spot — coaches without Lead status, coaches from the
other studio, even people who aren't coaches. Lead spots pay the Lead rate. After this fix, a
studio manager can only change who coaches a class through the normal Assign / claim / swap
actions, which already check Lead status, the studio, clashes and one-spot-per-class. You and the
GM can still correct a position directly, but only with a coach who is allowed in that spot.

## Today's paths

- `positions_write` (0001:411): any studio manager may INSERT/UPDATE/DELETE any position of their
  studio's classes directly, including `coach_id`, `role` and `class_id`. No eligibility check.
- The app writes positions only through security-definer functions (`assign_position`,
  `claim_position`, swaps, `drop_position`, `generate_classes`, `set_class_type`), which call
  `check_assignable` / `coach_eligible` / `swap_blocker`.
- Fix #4 (0013) added `positions_guard_lock` (security invoker) refusing manager writes to
  positions of verified classes.

## Decisions (orchestrator, final for v1)

- D1. Guard trigger on `positions` (security invoker; exempt postgres / service_role /
  supabase_admin, i.e. the definer functions and the server key). Must coexist with fix #4's
  `positions_guard_lock` (name order matters: say which fires first and why it doesn't matter, or
  make it not matter).
- D2. **Managers (non-admin):** a direct write may not set or change `coach_id`, `role`,
  `class_id`, `claimed_at` or `assigned_by`. INSERT only with `coach_id` null. DELETE only of a
  position with `coach_id` null. Refusal: 42501 "Use Assign to change who coaches a class."
  Everything else a manager could legitimately do directly (if anything) keeps working.
- D3. **Owner/GM:** direct writes allowed, but any resulting row with a coach must satisfy
  `coach_eligible(coach, class studio, role)` (active coach at that studio; Lead spots need Lead
  status) and one-spot-per-class; refusal 42501 with the same wording as `check_assignable`
  ("Lead positions need Lead status at this studio." / "This coach is not approved at this
  studio." / "Already coaching this class. One position per class."). This keeps their ability to
  correct past classes (Assign refuses started classes) without letting anyone into a Lead spot.
- D4. Every definer path that puts a coach into a position must already enforce eligibility —
  db lane confirms for claim, assign, swaps (request/respond/decide/do_swap), set_class_type,
  generate_classes; fix any that don't (in 0014, keeping fix #4's lock behaviour).
- D5. Existing rows are left alone; 0014's result line reports how many current positions have a
  coach who isn't eligible for that spot.
- D6. Migration 0014, one transaction, re-runnable; every earlier test, scenario and fix #1–#4
  guarantee keeps passing, except test 96 R09-mgr-pos-update (expects a manager coach change to
  succeed; it flips under D2 — justify in the report). Test 70 covers reads only.

## v2 decisions (after the checker's pre-mortem, `attack-list.md`)

- D7 (P1/S-9). `do_swap` re-runs `swap_blocker` for the target before moving the coach, so
  `decide_swap(approve)` refuses if the target lost Lead status, their membership or their active
  profile while the swap waited. Keep fix #4's lock order and eligibility-before-lock rule.
- D8 (P3/S-7). A change of `classes.studio_id` on a class that has any filled position is refused
  for everyone except postgres/service_role/supabase_admin (42501 "Move the coaches off this class
  before moving it to another studio."). Guard on `classes`, must coexist with fix #4's
  `classes_guard_lock` (lock message wins on verified classes).
- D9 (S-2). The Owner/GM eligibility check runs only when `coach_id`, `role` or `class_id`
  changes (or an INSERT carries a coach), so edits that leave the coach alone on old rows work.
- D10 (S-3, A-21). Name the new positions trigger so it sorts **after** `positions_guard_lock`
  (e.g. `positions_guard_write`): on a verified class the lock message wins.
- D11 (S-4). Owner/GM direct writes also get the clash check (same overlap query as
  `check_assignable`, "Clashes with another class: …").
- D12 (S-5). A manager INSERT must have `coach_id`, `assigned_by` and `claimed_at` all null.
- D13 (S-1). Eligibility is judged as of now. Correcting an old class for a coach who has since
  lost Lead status or left is refused (recorded as a limit; question 21).
- D14 (P2/S-6, S-8, S-11). Out of scope, recorded: a manager can grant Lead status, assign, then
  revoke it (managers set Lead status by design since fix #1 — question 21 asks Kelvin whether
  only Owner/GM should, or whether pay should use Lead status at the class date); deleting or
  cancelling an unverified class directly (audit #13); `coach_eligible`/`swap_blocker` callable by
  anyone (grants left as they are).

## Acceptance tests

- R-01 manager direct UPDATE coach_id on an unverified future position → 42501, unchanged
  (to a non-Lead coach in a Lead spot, to a coach of the other studio, to a non-coach, to an
  eligible coach — all refused: managers use Assign).
- R-02 manager direct INSERT of a position with a coach → 42501; with coach null → allowed.
- R-03 manager direct UPDATE role (support→lead) or class_id → 42501.
- R-04 manager direct DELETE of a filled position → 42501; unfilled → allowed.
- R-05 Owner/GM direct UPDATE coach_id to a non-Lead coach in a Lead spot / other-studio coach /
  non-coach / a coach already in that class → 42501; to an eligible coach → allowed; role change
  that would leave a non-Lead coach in a Lead spot → 42501.
- R-06 assign_position / claim_position / swaps / set_class_type / generate_classes keep working
  and keep refusing ineligible coaches (regression).
- R-07 service_role and postgres direct writes unchanged.
- R-08 fix #4: manager writes on verified classes still refused; Owner/GM corrections on verified
  classes still allowed when eligible.
- R-09 full suite incl. 70/80/90/95/96 and scenarios passes; re-runnable; one transaction.

## What must NOT change

The Assign button, claiming, dropping and swapping as coaches and managers use them today;
generate_classes and class types; every earlier fix.

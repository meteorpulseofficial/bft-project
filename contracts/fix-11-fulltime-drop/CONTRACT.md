# Fix #11 (a full-time coach can get off a class their manager assigned): contract

**Version:** 1 · **Frozen:** not yet (awaiting Aaron) · **Owner:** db lane (app follow-up K-32/K-33:
bft-builder) · **Last changed:** 2026-11-25 · by the db lane

## What changes (for Kelvin)

The build plan says a full-time coach's timetable is set by their manager and is read-only for
them. The app already stopped full-timers from *picking* classes, but the database still let them
*leave* one: drop it, hand it to someone through a swap, or take someone else's class through a
swap (and then drop that).

After this fix:
- **A full-time coach can't drop a class**, whoever put them on it and however far away it is:
  "Full-time coaches are scheduled by their manager." (the same message as when they try to pick a
  class).
- **A full-time coach can't ask for a swap and can't accept one.** They can still say no to a swap
  someone offers them. Asking a full-timer to take a class is refused up front: "That coach can't
  take it: Full-time coaches are scheduled by their manager."
- **Old swap requests don't sneak through.** A swap that was asked for before this fix, or before
  the coach became full-time, is refused when someone accepts it or a manager approves it. When the
  fix is installed, every open swap request with a full-time coach on it is cancelled and both
  coaches get a notice: "Your swap for <class> was cancelled: full-time coaches are scheduled by
  their manager."
- **Inactive coaches can't drop or swap.** A coach whose account is switched off, or who is no
  longer active at that studio, gets "Your account is inactive." or "You are no longer active at
  this studio." when they try to drop, ask for a swap or accept one.
- **Managers still decide.** The studio's manager (and the Owner / GM) can still take a full-timer
  off a class or put someone else on it, exactly as before; the coach is told. A full-timer who is
  also the manager of that studio may still drop their own class there (they could unassign
  themselves anyway).
- **Part-time coaches: nothing changes.** They can still drop any class more than 24 hours ahead,
  including one their manager assigned (question for Kelvin below), and swap as before.
- Switching a coach back to part-time gives them the normal part-time rules straight away.

## Today's paths (base a25a597, 0001–0019)

- `drop_position` (0013:311): not-yours → verified lock → free-drop window. No employment-type or
  active check; no cancelled-class check (F1; also seen: inactive profile / membership can drop; a
  manager at SBJ who is a full-timer at BGS can drop a BGS class).
- `request_swap` (0013:336) → `respond_swap` (0013:377) → `do_swap` (0014:211), or
  `decide_swap` (0014:234) when the studio needs approval: no employment-type check on either side
  (F2: a full-timer offloads a class; F3: a full-timer accepts a swap, getting round claim's
  refusal, then can drop it with assigned_by NULL; F4: rows opened before / while part-time still
  complete).
- `swap_blocker` (0007:129) and `swap_target_blocker` (0014:184): eligibility, same class, clash;
  nothing about full-timers.
- `claim_position` (0013) already refuses full-timers ("Full-time coaches are scheduled by their
  manager.") and inactive profiles ("Your account is inactive.").
- The app: `src/app/shifts/actions.ts` calls drop_position / request_swap / respond_swap and shows
  the error text; `shifts/page.tsx` already knows `isFullTime`.

## Decisions (orchestrator, final for this fix)

- D1 Key on `profiles.employment_type = 'full_time'` (not assigned_by). Read it without "where
  active" so inactive full-timers don't fail open; read / lock the profile consistently with the
  position lock (K-31).
- D2 Part-time DB rules unchanged (dropping a manager-assigned class stays allowed; question for
  Kelvin).
- D3 Full-timers: no drop, no outgoing swap request, cannot accept a swap; declining still allowed.
  swap_blocker / swap_target_blocker report full-timer targets. do_swap re-checks both sides, so old
  rows and manager approval are refused too.
- D4 Refuse inactive callers (profile inactive, or membership at that studio inactive) in
  drop_position, request_swap, respond_swap(accept).
- D5 A caller who manages the class's studio (`manages_studio`) may still drop even if full-time.
- D6 The migration cancels existing pending / awaiting_manager swap rows where requester or target
  is full-time, notifies both coaches, and the result line counts them.
- D7 Refusal text "Full-time coaches are scheduled by their manager." Order: not-yours (42501,
  first) → inactive → full-timer → existing checks (window / lock). Stated here and asserted.
- Out of scope: notice to the manager on part-time drops (SP-8); per-studio employment type (SP-7).

## Owner's technical choices (db lane; the orchestrator may overrule)

- T1 **One new internal helper, `assert_caller_active(p_studio uuid) returns employment_type`**
  (SECURITY DEFINER, search_path = public, EXECUTE revoked from PUBLIC / anon / authenticated /
  service_role). It reads the caller's profile `for share` (no "where active"), raises "Your account
  is inactive." when the profile is inactive or missing, raises "You are no longer active at this
  studio." when the caller has studio_members rows at that studio and none is active (any role;
  not asked of the Owner / GM), and returns the employment type. Definer because it must see the
  caller's own rows whatever RLS shows and take the row lock.
- T2 **Membership reading of D4:** "membership at that studio inactive" = rows exist, none active.
  Someone with no row at that studio at all is left to the existing checks (accepting a swap: "Not
  a coach at this studio." / the Lead text, as test 96 F2 expects). The full-timer rule still
  applies to them. Reason: telling a coach of another studio "You are no longer active at this
  studio" would be wrong.
- T3 **Order per function (D7), all P0001 unless noted:**
  - `drop_position`: "This is not your position." (42501) → inactive → full-timer (skipped when
    `manages_studio(class studio)`, D5) → verified lock → "Too close to class to drop (within N
    hours). Request a swap instead." A full-timer therefore gets the full-timer text on cancelled,
    started, verified and inside-window classes.
  - `request_swap`: not yours (42501) → inactive → full-timer (no D5 exemption: D5 covers drop; a
    manager assigns instead) → "Pick another coach." → swap_blocker ("That coach can't take it: …")
    → lock. Nothing inserted, nobody notified when refused.
  - `respond_swap(accept)`: "This request is no longer open." → inactive → caller full-time →
    requester full-time (profile `for share`) → swap_blocker → lock → manager step or do_swap. An
    old request from a full-timer never reaches the manager. `respond_swap(decline)`: unchanged.
  - `swap_blocker`: … cancelled → started → **full-time target** → eligibility → same class →
    clash. `swap_target_blocker`: no longer exists → **full-time target** → eligibility → …
  - `do_swap`: both profiles locked `for share` (id order) → requester full-time → swap_target_blocker
    (target full-time / eligibility) → lock → move. `decide_swap` body unchanged (it calls
    swap_target_blocker, then do_swap); reject unchanged.
- T4 **Race (K-31):** the employment type is read under a FOR SHARE lock on the profile row, held to
  commit. The Owner's change (an UPDATE of profiles) either commits first (the call waits, then sees
  full-time) or waits until the call commits. Both orders proven with two sessions
  (fix11_apply.sh S4).
- T5 Same signatures, create or replace (grants and the one overload each test 99d counts are kept);
  every re-created function SECURITY DEFINER with search_path = public, as before. Re-created:
  drop_position, request_swap, respond_swap, do_swap, swap_blocker, swap_target_blocker. Not
  touched: claim_position, assign_position, decide_swap, check_in, report_present,
  submit_absence, decide_absence, set_attendance, every trigger.
- T6 D6 cancellation text: title "Swap cancelled", body "Your swap for <fmt_class> was cancelled:
  full-time coaches are scheduled by their manager.", link /shifts, to requester and target.
  decided_at = now(). Result line: "Full-time coaches can no longer drop a class, ask for a swap or
  take one; inactive coaches can no longer drop or swap. Open swap requests cancelled because a
  full-time coach was on them: N." A re-run cancels nothing and prints 0 (functions and rows
  identical).
- T7 House style: one transaction, precondition on 0019's marks ("migration 20: migration 19 (fix
  #13) must be applied first"), end checks (one overload each, definer + search_path, this file's
  texts in the bodies, grants, no open full-timer swap left), result line, baseline line.

## Consequences to know (recorded, not decided by the db lane)

- **Re-runs:** re-running 0007, 0013 or 0014 after 0020 brings back their old bodies of these
  functions (the hole reopens; fix11_apply.sh S2 shows it and shows 0020 again restoring them). The
  ops/migrate.sh ledger never re-runs an applied file.
- **Managers who are full-timers:** may drop at a studio they manage (D5) but may not ask for or
  accept a swap there (T3). They use Assign.
- **Approval studios:** the "Swap to approve" notice already sent to managers for a row D6 cancels
  stays in their list; the row itself is cancelled, so approving it says "This swap is no longer
  waiting."

## Acceptance tests (where)

- `supabase/tests/99e_fix11_fulltime.sql` — 74 checks, K-01..K-29 (see attack-list.md coverage
  map). On base (a25a597, 0001–0019) 36 fail: every full-timer / inactive refusal and the catalog
  checks C01–C06; the other 38 pass on base and after (controls: manager / Owner / GM still move a
  full-timer, part-time drop and swap, check_in, report_present, absences, PT, claim, nobody else
  frees the position, staff drop, grants, definer).
- `supabase/tests/scenarios/fix11_apply.sh` — K-30, K-31: S1 apply on 0019 with open full-timer
  swaps (counts 2, cancels exactly those, notices, positions unchanged, baseline false → true, every
  baseline line true, re-run identical with 0), S2 13/14 after 20 reopen and 20 restores, S3
  precondition at 0018, S4 the race both orders.
- Existing tests changed: `tests/scenarios/fix13_apply.sh` S1-all-baseline-lines-true now evaluates
  the baseline lines and counts the migration files up to 0019 only (its database stops at 0019, so
  the new 0020 line is false there by design). No other test changed; full `tests/run.sh` passes.
- `ops/baseline-checks.tsv` — line for 20260928000020.

## What must NOT change

Part-time drop / swap rules (R-72 window), manager assign / unassign / reassign and their notices,
claim_position and its text, check_in, report_present, submit_absence, decide_absence, PT logging,
fix #4 lock, fix #5 eligibility, fix #13 record guards, every earlier test and scenario.

## App follow-up (bft-builder; K-32, K-33, not db lane)

Shape change for the app: refusal texts only (no new RPC, no signature change). The new texts the
app may show: "Full-time coaches are scheduled by their manager.", "That coach can't take it:
Full-time coaches are scheduled by their manager.", "Your account is inactive.", "You are no longer
active at this studio." The app may hide Drop / Swap / Accept for full-timers (it already knows
`isFullTime`) and drop full-timers from the swap-target list; the database refuses either way.

## Open (for Kelvin, via the orchestrator)

- SP-8 / D2: should a part-time coach be able to drop a class their manager assigned (today: yes,
  more than 24 h ahead), and should the manager be told when a part-timer drops?
- SP-7: is employment type per person (today) or per studio (a coach full-time at one studio and
  part-time at another)?

## Release order

Run 0020 after 0019. No app change is needed for the fix to hold; the app follow-up only improves
what full-timers see.

## History

- v1 2026-11-25: written by the db lane from D1–D7 and the checker's attack list (K-01..K-34).

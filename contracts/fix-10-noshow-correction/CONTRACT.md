# Fix #10 (correcting a no-show to attended leaves the strike): contract

**Version:** 3 · **Frozen:** not yet (awaiting Aaron) · **Owner:** db lane (no app change required) ·
**Last changed:** 2026-11-24 · by the db lane (round 3: checker finding 1, D12 added by the orchestrator)

## What changes (for Kelvin)

If a manager marks a coach as a no-show by mistake and then corrects it to "attended" or "late",
the no-show is now really gone: no strike, no booking pause from it, and the coach gets a message
saying so ("... It won't count as a strike."; plus "Booking is open again." if that correction
lifted a pause). Today that only works while the no-show is still undecided; once a manager has
decided it (excused or not), the strike stays forever.

Who may correct:
- an **undecided** no-show: any manager of the studio (as today);
- a **decided** no-show (excused or not): **only the Owner or GM** — a manager gets "This no-show
  has already been decided. Ask the Owner or GM to correct it." (same rule as changing a decision,
  question 27);
- **nobody marks their own attendance or removes their own no-show** except the Owner/GM: a
  manager who also coaches gets "You can't mark your own attendance. Ask another manager, the
  Owner or GM." — also when the position has since been given to someone else. (Approving their
  own QR check-in through "verify class" still works when there is no no-show on it — it is the
  scan that counts there.)

Every removed no-show is kept in a record only the Owner and GM can see (who decided it, who
corrected it, the coach's explanation and photo path, whether it was counting as a strike).

## Today's paths (base 9eda5ec, 0001–0017)

- `set_attendance` (0017 ~l.330): upserts attendance; `no_show` inserts an absence (on conflict do
  nothing) and notifies; anything else runs `delete from absences where position_id = … and
  decision is null` — decided absences stay. No check that the caller is not the position's coach.
- `decide_absence` (0017): role check first without a lock — an absence already deleted gives
  42501 "Not allowed."; deleted while waiting for the lock gives "This absence no longer exists.".
- `submit_absence` (0017): `for update`; missing row → "Not found.".
- `verify_class` (0013) calls `set_attendance` for every pending position with a QR check-in.
- `assign_position(NULL)` after start deletes attendance, keeps the absence (fix #13 territory).
- `set_class_cancelled` keeps absences; `set_attendance` refuses cancelled classes.
- Absences: RLS on, one select policy, no write policies. No `audit_log` table exists.

## Decisions (orchestrator, final for this round)

- D1 Delete, not void. Before deleting, copy the row into `public.absence_corrections` (absence id,
  position_id, coach_id, studio_id, class_starts_at, reason/explanation/evidence path, decision,
  decided_by, decided_at, decision note, corrected_by = auth.uid(), corrected_at, new_status). RLS
  on, select policy `is_admin()` only, no insert/update/delete policies, no grants to anon; writes
  only via the definer function. Absences keep no write policies.
- D2 Any decision (valid or invalid) or undecided absence goes when attendance becomes attended or
  late.
- D3 Removing a DECIDED absence: `is_admin()` only. Non-admin manager → refused, nothing changed,
  "This no-show has already been decided. Ask the Owner or GM to correct it." Undecided: managers
  as today.
- D4 `set_attendance` on a position whose coach is the caller → refused unless `is_admin()`, "You
  can't mark your own attendance. Ask another manager, the Owner or GM." (any status).
  Inactive/other-studio manager → existing 42501 "Not allowed.".
- D5 Flip back to no_show after removal = fresh no-show (new absence, new due_at, decision null, one
  notification). no_show → no_show while an absence exists: no change, no notification.
- D6 Notification to the coach only when an absence row was actually removed: "Attendance
  corrected: your no-show for <class name> on <'Dy FMDD Mon, FMHH12:MIam' in studios.timezone> was
  changed to <attended|late>. It won't count as a strike." + " Booking is open again." only if the
  coach was paused at that studio before and is not after. No pay promise, no manager
  notification, never stamp strikes_cleared_at.
  **Amended (round 2, orchestrator):** the body is "Your no-show for <class> on <time> was changed
  to <attended|late>. It won't count as a strike." (+ " Booking is open again."); title stays
  "Attendance corrected".
- D7 Evidence files: no storage change; evidence path kept in absence_corrections. Open (PDPA).
- D8 Out of scope, current behaviour asserted: assign_position(NULL) after start with a decided
  absence (strike stays; fix #13); set_class_cancelled after a no-show (Kelvin question).
- D9 Concurrency: set_attendance locks the position/absence row; decide_absence / submit_absence
  never 42501 or raw-error on a row removed by a concurrent correction. The coach never ends with a
  strike-promising notice newer than the correction and no correction notice after it.
- D10 Existing stale rows (attended/late with an absence still present) are not changed; the result
  line reports counts by decision and the coach/studio pairs paused because of them. Kelvin decides.
- D11 Re-run safety as in fixes #8/#9; 0016 and 0017 after 0018 refused.
- D12 (round 3, orchestrator; overrides v2's "another manager may still correct an undecided
  absence whose owner differs from the current coach"). Non-admin: when the position's absence
  belongs to someone other than the position's current coach, set_attendance with attended or
  late is refused, nothing changes: "This no-show belongs to a coach who no longer holds this
  position. Ask the Owner or GM." This includes the verify_class-shaped call, so verify_class
  fails closed in that state (only reachable through the audit #13 trick). A no_show in that state
  keeps today's behaviour (N1, below). Owner/GM may still remove it; the owner's notice body is
  then "Your no-show for <class> on <time> was removed by the Owner or GM. It won't count as a
  strike." (+ " Booking is open again."); title unchanged. Refusal order: right after D3.

## Owner's technical choices (db lane; the orchestrator may overrule)

- T1 Notification: title `Attendance corrected`, body per amended D6 ("Your no-show for …").
  "<class name>" = the class type name (`class_types.name`, 'class' if missing); the time is the
  class start **stored on the absence** (`absences.class_starts_at`, fix #9) in the class's studio
  zone, so a class moved later by the Owner/GM does not change the time named (round 2, finding 3);
  the class's current start only for a damaged row whose stored value is not finite.
- T2 D4 exemption (needed, otherwise `verify_class` would fail for a manager-coach on their own
  class): the self call is allowed only when it is exactly the call `verify_class` makes —
  attendance pending with a QR check-in, `no_checkin` false, minutes equal to the stored minutes,
  status = late if minutes > the studio's `late_grace_min` else attended. Same effect as running
  verify_class, which that manager may do anyway. A pending position has no absence, so this never
  removes one. Any other self call (incl. no_show) is refused.
  **Round 2 (finding 1):** D4 is also judged on the absence's owner: if the position's absence
  belongs to the caller (non-admin), any status is refused, whoever holds the position now (a
  reassignment after the no-show, e.g. move the class forward → assign_position to someone else →
  move it back, must not let its owner remove it). The exemption additionally requires that the
  position has **no absence**; with one, verify_class by that manager-coach is refused too (fails
  closed). Another manager may still correct an undecided absence whose owner is not the current
  coach (record and notice go to the owner); Owner/GM any. **Superseded by D12 (v3):** a
  non-admin manager is refused in that state; Owner/GM only.
- T3 Refusal order in set_attendance: invalid status → 42501 role → (on rows read under the T4
  locks) no coach → D4 self → cancelled → not started → fix #4 lock → D3 decided → D12 owner
  no longer holds the position (v3). (So a manager on a locked class gets the fix #4 text
  first, unchanged, A-06.)
- T4 Locks: class FOR SHARE (as before, before the role check) → position FOR NO KEY UPDATE →
  absence FOR UPDATE → attendance FOR UPDATE (all after the role check). **Round 2 (finding 2):**
  the coach, D4, its exemption and D3 are all decided on rows read under these locks (race 6:
  a no-show marked by another manager while the self call waits is seen, the call is refused).
  check_in / report_present take class then attendance: same order. **Round 2 (finding 6):**
  before removing an absence, a transaction advisory lock per (coach, studio) is taken, then
  paused-before / paused-after are computed: two simultaneous corrections for one coach and
  studio run one after the other and exactly one notice can say "Booking is open again." (race 7:
  the first, which lifted the pause). The no-show and correction notices are stored with
  `created_at = clock_timestamp()` after the locks, so notices sort in the order the changes
  happened (D9). The advisory lock is taken after the row locks, so two corrections inside ONE
  transaction, run against another transaction doing the same two in the opposite order, could
  deadlock (Postgres rolls one back); no app path does this today (comment in the migration).
- T5 decide_absence on an id not in absences: if it is in absence_corrections and the caller
  manages its studio → "This absence no longer exists."; else 42501 as before (no leak).
  submit_absence unchanged: "Not found." (its existing text) — allowed by D9.
- T6 absence_corrections also stores due_at, submitted_at, absence_created_at,
  counted_as_strike (did it count at the moment of correction), minutes_late. Only FK: studio_id →
  studios on delete cascade (like absences); no FK on position/coach/people so the record outlives
  the position and never blocks a profile deletion. Grants: SELECT to authenticated and
  service_role only; nothing to anon or PUBLIC.
- T7 set_attendance keeps its existing grants (anon has EXECUTE today and gets 42501 without a user
  id; kept, recorded). service_role without a user id gets 42501 (today's behaviour, kept).
- T8 D11: 0018's set_attendance writes `timezone(v.studio_tz, …)` instead of 0017's `at time zone
  v.timezone` and keeps the lock text in two pieces, so 0017's and 0016's own preconditions refuse
  a re-run after 0018 (messages name the file before them, as with 13 in fix #9). Re-running 0013
  after 0018 is not safe (already recorded in 0017); the migrate.sh ledger never re-runs files.

## Acceptance tests (where)

- `supabase/tests/99c_fix10_noshow_correction.sql` — 113 checks: A-01..A-17, A-21 (after every
  check), A-23, A-27, sequential halves of A-18/A-19, R2-* (round 2 findings 1, 3, 5), R3-*
  (D12: the checker's 3a and 3b through the real functions, late, N1, Owner/GM text with and
  without the booking sentence, refusal order lock → D3 → D12 and D4 before D12).
- `supabase/tests/scenarios/fix8_race.sh` — races 1b, 1c, 1d (A-18 both orders), 4, 4b (A-19), 5,
  5b (A-20), 6 (finding 2), 7 (finding 6), real COMMITs in two sessions. Round 2 (finding 4): A
  signals "statement done" by touching a file from psql instead of being polled through
  pg_stat_activity; A waits up to 30 s for B to block. 10 consecutive runs clean, and 10 more
  with a full run.sh running alongside.
- `supabase/tests/scenarios/fix10_apply.sh` — A-24, A-25 (result line on seeded stale rows, re-run,
  0010/0012 re-run, 0016/0017 refused, precondition at 0016, baseline line false → true).
- `supabase/tests/70_access_matrix.sql` — absence_corrections added to the read matrix (Owner/GM
  all rows, 16 other roles nothing; 4 sensitive columns); anchors 40→44 columns, 1098→1188 cells.
- `ops/baseline-checks.tsv` — line for 20260928000018.

## What must NOT change

Strike rule (fix #8/#9), deadline, decide/submit refusals and texts, fix #4 lock and its text,
verify_class, claim rules, every earlier test and scenario.

## Open (for Kelvin, via the orchestrator)

- D7 / PDPA: after a correction the coach may delete their uploaded evidence file
  (`absence_evidence_in_use` looks at absences only); the path stays in the record. Keep the file,
  let the coach delete it, or delete it automatically?
- D8: unassigning a coach after the class started leaves a decided strike (fix #13); cancelling a
  class after a no-show keeps the strike.
- Audit #13 (recorded here, not fixed): N1 — after the reassignment trick, marking the new coach
  no_show records nothing for them (the old owner's absence stays on the position); N2 — deleting
  a class (or position) cascades its absences away, strikes included.
- D10: what to do with existing attended/late positions that still carry a decided absence on
  production (the result line gives counts).
- Should Finance see absence_corrections? (D1 says Owner/GM only.)

## Release order

No app change is needed: the app already lists notifications by title/body and calls
set_attendance / decide_absence; the new refusal texts arrive as normal error messages. If the app
offers "mark attended" on a decided no-show to managers, they will now see the D3 text.

## History

- v1 2026-11-24: written by the db lane from D1–D11 and the checker's attack list (A-01..A-27).
- v2 2026-11-24: fresh reviewer round 2. D6 body amended by the orchestrator (no repeated title).
  T1 time from the absence's stored class start; T2 D4 also on the absence's owner, exemption only
  with no absence; T3/T4 decisions under the locks, per-(coach, studio) advisory lock; race
  handshake made deterministic. Shape change for the app: notification body text only.
- v3 2026-11-24: checker round 3 finding 1 (absence laundered through a reassignment: a manager
  truthfully marking the new coach, or a routine verify_class, removed the old owner's absence and
  told them they attended). D12 added by the orchestrator: refused for non-admins (right after
  D3); Owner/GM removal uses "... was removed by the Owner or GM. ..." when the owner no longer
  holds the position. N1/N2 recorded for #13. Advisory-lock ordering note added. Shape change for
  the app: one new refusal text and one new notification body variant.

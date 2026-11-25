# Fix #11: checker's pre-mortem (2026-11-25, verbatim in substance)

Probes on base (a25a597, 0001–0019): scratchpad fix11/seed.sql + probe.sql (P1–P17).
Hole: a full-time coach can leave a class their manager assigned: drop_position (F1),
request_swap → respond_swap / decide_swap (F2), accepting a swap gets round claim_position's
full-timer refusal and the class can then be dropped with assigned_by NULL (F3), swap rows opened
before the fix / before becoming full-time still complete in do_swap (F4). Also seen: an inactive
profile or membership can still drop; a manager at SBJ who is a full-timer at BGS can drop a BGS
class.

K-01 FT drop manager-assigned future class outside 24h → refused with full-timer message;
position/attendance/swaps unchanged.
K-02 FT drop at +24h01m and +23h59m → both refused with full-timer message.
K-03 FT drop on cancelled class → refused.
K-04 FT drop started/verified → refused, fixed asserted order.
K-05 FT drop own self-claimed position from part-time days (assigned_by=FT) → refused.
K-06 FT2 drop swapped-in position (assigned_by NULL) → refused.
K-07 FT drop someone else's / nonexistent position → "This is not your position." 42501,
not-yours first.
K-08 inactive FT (profiles.active=false) → refused, must not fail open.
K-09 FT with inactive membership, active profile → refused.
K-10 MC (manages SBJ, full-timer at BGS) drop at BGS → refused; assign_position(null) still
refused at BGS.
K-11 MB (manages BGS, full-timer, holds BGS position) → assign_position(null) works; drop_position
allowed per D5, asserted.
K-12 FT request_swap inside and outside 24h → refused before any swap_requests insert or notice.
K-13 FT respond_swap(accept=true) → refused, position unchanged.
K-14 FT respond_swap(accept=false) → allowed (declined, notice).
K-15 PT request_swap(target FT/FT2) → refused up front; swap_blocker gives the reason.
K-16 old pending FT→PT2, PT2 accepts → refused in do_swap; FT keeps the class.
K-17 old awaiting_manager from FT, M approves → refused; M reject works.
K-18 old PT→FT2, FT2 accepts or M approves after FT2 accepted → refused.
K-19 request opened while FT part-time, Owner switches to full_time, target accepts → refused.
K-20 Owner switches FT to part_time → can drop/swap under normal 24h rule.
K-21 M assign_position(pos,null) on FT's class → works (notice, attendance/swaps cleared);
Owner/GM across studios too.
K-22 M assign_position(pos,PT) on FT's class → works, both notified.
K-23 part-time unchanged: PT self-claim drop at +24h01m allowed, +23h59m refused "Request a swap"
(R-72).
K-24 PT↔PT swap, approval off/on unchanged.
K-25 FT check_in, report_present, submit_absence, decide_absence (by M), log PT on assigned
classes unaffected.
K-26 FT claim_position still refused same message.
K-27 other studio's manager, Finance, PT, anon cannot free FT's position.
K-28 Owner/GM staff or GM holding a position: drop behaves as non-full-timer; rule must not catch
'staff'.
K-29 99d C-check green: one overload each of drop_position, claim_position, do_swap; grants
unchanged.
K-30 re-run migration = same result; applying on 0019 with open FT swap rows counts/cancels them.
K-31 race: Owner flips FT to full_time during drop_position → either order, no half state.
K-32/K-33 app (not the db lane — app owner handles).
K-34 full suite (tests/run.sh) + scenarios pass, incl. 50, 60, 70 'ft', 96/97/99d swap and drop
cases.

Coverage map: every check id in tests/99e starts with its K- number (K01-…, K28-…); C-* = catalog
(K-29, and C05/C06 for K-31's lock). K-08 and K-09 also cover part-time callers (D4 applies to
everyone) and the D7 order inside respond_swap ("no longer open" → inactive → full-timer);
K09-accept-no-membership records T2 (no row at the studio at all → the eligibility text). K-12 also
covers a full-timer who manages the studio (no outgoing swap; D5 is drop only). K-30, K-31:
tests/scenarios/fix11_apply.sh (S1 apply / re-run / counts / notices, S2 13–14 after 20 and 20
again, S3 precondition, S4a/S4b the race with two sessions). K-34: full tests/run.sh (every earlier
file incl. 50, 60, 70, 96, 97, 99d, then run_scenarios.sh), fix6_race, fix8_apply, fix8_race,
fix9_apply, fix10_apply, fix13_apply, ops/tests/run-kit-tests.sh.

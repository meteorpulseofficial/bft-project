# Fix #12: checker's pre-mortem (2026-11-25, verbatim in substance)

Probes on base (29b8d2d, 0001–0020): scratchpad fix12/seed.sql + p.sql. All PT writes go straight to
pt_sessions (no RPCs); the only guard is trigger pt_guard (0005, rewritten in 0009).
F1 manager self-approves at 100% (insert approved, or pending → approved). F2 other routes: MC
(manages SBJ, coaches BGS) self-approves at SBJ or moves own row BGS → SBJ and approves; manager
reassigns coach_id to self on approved / pending row; un-approve → edit → re-approve own row;
Owner / GM self-approve. F3 decided rows: amount, %, date (other month), client, coach, studio,
status flips, delete — all allowed, no history exists. F4 reviewed_by / reviewed_at / created_by
forgeable on insert / update. F5 manager enters approved PT for non-members, inactive, Finance.
F6 inactive profile and Finance (member_of_studio counts Finance everywhere) can log PT. F7 silent
no-op when pt_guard coerces a manager-coach's own approval (should raise).

P-01 M inserts own row approved 100% → saved pending at default, reviewed_by/at null.
P-02 M updates own pending row to approved / rejected → refused with message, unchanged.
P-03 M changes coach_pct on own pending row → refused.
P-04 MC own row at BGS / SBJ → pending; MC approving either → refused.
P-05 MC moves own pending row BGS → SBJ → refused (studio immutable).
P-06 manager sets coach_id to self on another's pending row → refused.
P-07 same on approved row → refused.
P-08 M2 sends own approved row back to pending → refused.
P-09 Owner / GM approving own → allowed, recorded.
P-10 manager updates each column of an approved row → refused, one check per column.
P-11 same on rejected row.
P-12 manager deletes approved / rejected → refused.
P-13 Owner / GM correction per D3 (status / amount / % / note on another's row allowed + recorded;
     date / client / duration / coach / studio refused; own decided row refused).
P-14 Finance update / delete → no rows.
P-15 coach update / delete own decided row → no rows.
P-16 two managers approve same pending row concurrently (50% vs 100%) → exactly one wins.
P-17 caller-set reviewed_by / at / created_by ignored.
P-18 manager approves → reviewed_by = caller ≠ coach.
P-19 manager inserts for non-member (c2 at BGS), inactive pi, Finance without membership → refused;
     Owner / GM as coach without membership → allowed.
P-20 inactive profile logs → refused; inactive membership → refused.
P-21 Finance without membership logs own → refused; Finance with coach membership → pending.
P-22 approving a row whose coach became inactive → allowed.
P-23 every insert / update / delete by every role writes one history row with before / after.
P-24 history: no writes by anon / authenticated incl. Owner / GM; read Owner / GM only; coach
     can't read.
P-25 truncate pt_sessions / history as service_role → refused.
P-26 history survives PT row delete.
P-27 coach logs own PT → forced pending default (tests 40, 90 R08-01..04 unchanged).
P-28 coach edits / deletes own pending; two-studio coach gets each default.
P-29 M2 approves c1 at 60% → coach 180 / studio 120 (R-51); default 50% (R-50); reject → not in
     extra_earnings (R-53).
P-30 manager enters session for another coach at their studio → approved, reviewed_by = manager
     (R-54); M approves M2's and vice versa.
P-31 full-timer logs PT.
P-32 postgres / service_role seed inserts of approved rows with reviewed_by null work
     (ops/seed/data.sql, tests 70, 90).
P-33 extra_earnings totals in 40 and 70 unchanged; read matrix unchanged.
P-34 re-run = same; counts existing self-approved / null-reviewer rows, changes nothing.
P-35 full suite + scenarios + ops/tests/run-kit-tests.sh pass.
P-36 (skipped by the orchestrator for this fix.)

Coverage map: every check id in tests/99f starts with its P- number (P01-…, P23-…); C-* =
catalog (grants, definer / invoker, triggers, RLS, messages in the body). P-09/P-13/P-19/P-22 are
asserted as decided (D1, D3, D5). P-16 and P-34: tests/scenarios/fix12_apply.sh (S3 race with two
sessions, before and after; S1 apply / re-run / counts; S2 0009 re-run; S4 precondition). P-27,
P-32, P-33: also the unchanged tests 40, 70 (seed and extra_earnings cells) and 90 R08-01..04,
R09-05/06/10. P-35: full tests/run.sh, every scenario script, ops/tests/run-kit-tests.sh.

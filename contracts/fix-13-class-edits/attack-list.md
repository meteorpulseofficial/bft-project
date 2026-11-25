# Fix #13: checker's pre-mortem (2026-11-25, verbatim in substance)

Probes on base (afbaaee, 0001–0018): scratchpad holes.sql (H1–H16), gen.sql (G1), selfpos.sql
(H12-self); fix #10 leftovers in contracts/fix-10-noshow-correction/repro/ (launder_back.sql,
transfer.sql = N1, delete.sql = N2 reproduce; launder.sql, launder_verify.sql refused by D12).
Hole: a manager can write classes and positions directly (start time, headcount, cancel, type,
special event, duration, studio, insert, delete), skipping the functions' checks and the coach
notices; deleting a class or an emptied position cascades its no-shows away; reassigning a position
after a no-show moves or hides it; generate_classes accepts past ranges; anon/authenticated hold
TRUNCATE.

A-01 update starts_at on a future class with a coach → refused.
A-02 update starts_at on a started class, including a manager-coach on their own class → refused.
A-03 boundaries: 1 µs before start, starts_at = now() → same refusal.
A-04 direct headcount update → refused; verify_class still sets it.
A-05 verified_at / verified_by update or insert → refused (permission denied now; the message changes
from 0013's text).
A-06 direct cancel / uncancel, forged cancelled_by → refused; set_class_cancelled still notifies and
cancels swaps.
A-07 class_type_id direct → refused; set_class_type unchanged.
A-08 is_special_event / duration_min → refused.
A-09 studio_id → refused.
A-10 insert past / cancelled / special / headcount / forged source / glofox_id / other studio's
template_slot → refused.
A-11 insert future direct → refused; generate_classes works from today and refuses a past p_from.
A-12 delete a future class with coaches → refused; delete a started class with an absence → refused,
absence kept.
A-13 delete as Owner/GM (refused via API), service_role, postgres → refused while an absence exists
(RESTRICT); allowed without an absence for postgres / service_role.
A-14 assign_position(NULL) after start on a position with an absence, by another manager, by a
manager-coach on themselves, by Owner/GM → refused.
A-15 delete an empty position holding an absence → refused for everyone.
A-16 insert a position on a started or future class via API → refused.
A-17 launder_back.sql → refused at the reassignment; MC's absence stays; no "Attendance corrected".
A-18 transfer.sql → refused at the reassignment.
A-19 delete.sql → refused, absence kept.
A-20 launder.sql, launder_verify.sql → still refused.
A-21 H15 → the first move is refused.
A-22 H14 → the move is refused; lateness stays 10.
A-23 other-studio manager, coach, Finance, inactive manager, inactive GM, anon → refused, unchanged.
A-24 Owner/GM editing a verified class's time via API → refused (E1).
A-25 a bulk statement with one illegal row → whole statement refused.
A-26 TRUNCATE as anon / authenticated → permission denied on all listed tables.
A-27 FK cascade paths still work (template slot delete nulls template_slot_id, etc.).
A-28 set_class_type, generate_classes, claim, drop, swap, check_in, report_present, verify_class
behave as before (full suite).
A-29 re-run 0019 → same result; 10/12 after 0019 safe; 16/17 refused; 13/14 after 0019 per E3.
A-30 existing odd rows → left alone and counted.
A-31 n/a (no move RPC this round).
A-32 the baseline line is false before 0019 and true after; ops migrate --baseline passes.

Coverage map: every check id in tests/99d starts with its A- number (A01-…, A28-…); W-* = second
wall (0013/0014/0019 guards behind the revoked grants); C-* = catalog (E7). A-29, A-30, A-32:
tests/scenarios/fix13_apply.sh (S1–S3) and ops/tests/run-kit-tests.sh. A-28: full tests/run.sh
(every earlier file), run_scenarios.sh, fix6_race, fix8_apply, fix8_race, fix9_apply, fix10_apply.
A-17..A-20 are checked twice in 99d: the repro as written (refused at its first raw class write) and
with the class moved by postgres first, so the reassignment / delete step is judged on its own.

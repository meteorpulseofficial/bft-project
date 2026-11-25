# Fix #4: checker's pre-mortem attack list (2026-11-21 07:26 UTC, verbatim in substance)

Baseline 26e6010 passes. Probes (old code): scratchpad/fix4/probe.sql, probe2.sql; P1–P9, Q1 all succeed today.
Key point: D5's guard exempts postgres, so it can't see security-definer functions (all run as postgres) — each definer writer needs its own lock check (→ contract D9).

Write paths: classes — I: classes_write (0001:406); D: generate_classes (0001:276), set_class_cancelled (0007:318), set_class_type (0003:47), verify_class (0007:466); FKs: template_slots delete nulls template_slot_id (0001:124), studios delete cascades. positions — I: positions_write (0001:411) incl. class_id change; D: generate_classes, set_class_type (insert/delete surplus); claim_position / assign_position(coach) / respond_swap→do_swap blocked after start by check_assignable/swap_blocker (0006:24-25, 0007:136-137); drop_position blocked from free_drop_hours; **assign_position(pos, NULL) no time/lock check (0007:296-297)**; **decide_swap→do_swap no time/lock check (0007:266-287, 218-233)**. attendance — D only: check_in (:387), report_present (:419), set_attendance (:440), verify_class; deleted by drop_position (:192), do_swap (:227), assign_position (:304); cascade from position delete (0007:45). absences — D: set_attendance (:451/:460), submit_absence (:509), decide_absence (:524); cascades (0007:74-76). No triggers today on these tables.

set_attendance
- A-01 manager, verified class, attended→no_show → refused, unchanged, no absence/notification.
- A-02 manager, verified class, coach row pending or missing (admin added a position after lock) → refused.
- A-03 Owner/GM correct verified class both ways → allowed, class verified_at/by unchanged; no_show creates absence; →attended deletes only an undecided absence.
- A-04 manager/Owner/GM on cancelled class (verified and not) → refused for all.
- A-05 future class, any status → refused, zero absences/notifications.
- A-06 boundary: starts_at = now() allowed; now()+1µs refused (tests relative to transaction now()).
- A-07 in-progress unverified class → as today incl. no_show → absence.
- A-08 coach / Finance / other-studio manager on locked or cancelled class → "not allowed" first (no state leak).
- A-09 errcodes per refusal (→ D10); old "Not allowed." was P0001 — check tests/app matching it.
verify_class
- A-10 manager on cancelled / future / already-verified → refused; nothing stamped; no attendance written by its loop.
- A-11 Owner/GM "Update" on verified class (app shows the button) → headcount only, no re-stamp (D12).
- A-12 verify 1 minute after start with all marked → locks while running (D13 accepted).
- A-13 started class with no filled positions → locks with v_open = 0 (confirm wanted).
- A-14 normal verify still works; its internal set_attendance calls must not trip the lock mid-loop.
check_in / report_present
- A-15 locked class, no attendance row, scan in window → nothing written (old inserts).
- A-16 locked class, pending row with row verified_at null → unchanged (old updates).
- A-17 run A open → B locked (same day, within gap) → C: A written, B skipped and not in `covered`, run continuity per D11.
- A-18 locked first class → excluded; lateness from next open class (D11).
- A-19 report_present locked (no row / pending row) → P0001 message (D11); 2h/48h edges.
- A-20 report_present on cancelled class → P0001 (D11).
Definer paths on a locked class
- A-21 manager assign_position(pos, NULL) on verified past class (old P2: succeeds, deletes attendance) → refused.
- A-22 manager decide_swap(approve) on a swap left awaiting_manager past verification (old Q1: coach changes, attendance deleted, class stays verified) → refused.
- A-23 manager set_class_cancelled(true/false) on verified class (old P3: cancelled while verified) → refused for managers.
- A-24 manager set_class_type on verified class → refused; app setDayClassType (app/manage/actions.ts:115-134) stops at first refusal leaving earlier classes changed (→ D15).
- A-25 a locked class not yet started (legacy / admin-set): claim, assign, drop, request/respond swap pass their started-checks → refused.
Direct writes
- A-26 manager UPDATE any column of a locked class incl. no-op, clearing verified_at (old P5), changing verified_by; DELETE → 42501, unchanged.
- A-27 manager sets verified_at/by on an unlocked class directly → 42501.
- A-28 manager INSERT class with verified_at preset and verified_by = Owner (old P9) → refused (trigger on INSERT too).
- A-29 manager positions: INSERT into locked; UPDATE coach_id/role/seq; DELETE (old P6 cascades attendance); UPDATE class_id locked→open (old P7) and open→locked → 42501 (check old and new class).
- A-30 positions trigger class lookup under RLS: null → must not fail open (D16).
- A-31 Owner/GM/service_role/postgres each edit allowed; manager edits of unverified classes unchanged.
- A-32 manager deletes a template slot whose class is verified: FK nulls template_slot_id as owner → allowed (check current_user before auth/is_admin).
- A-33 definer functions still work: verify_class stamping; generate_classes over a range containing verified classes.
- A-34 move a future class's starts_at into the past directly, mark no_show, move back → absence survives on a future class (audit #13, D14 out of scope).
Fixes #1–#3
- A-35 re-run 0013 twice; re-run 0010 and 0012 after 0013 (0010 refuses invoker readers of studios; 0012 refuses definer functions naming checkin_token or returning studios rows; new guards must not touch studios; if check_in is re-created keep check_in(text) definer).
- A-36 10–95 and scenarios pass; 70 unchanged except pins for this finding.
- A-37 one transaction; partial failure leaves nothing changed.
App
- A-38 390px: manager "Verified — locked" no buttons; Owner/GM controls + note; refusals shown.
- A-39 stale page: admin verifies, manager clicks No-show → refusal shown, page refreshes, no stale optimistic status.
- A-40 verifyAllCheckedIn mixed (verified, cancelled, future, other studio's id, pending) → summary names each; hidden labels "A class"; one throw doesn't stop the rest.
- A-41 page lists only status = 'scheduled' (page.tsx:29); server clock vs DB now() boundary.
- A-42 decideSwap / decideAbsence discard DB errors (verify-actions.ts:61-80) → once A-22 refuses the manager sees nothing (→ D15).

Spec problems → contract v2: S-1 → D9; S-2 → D14; S-3 → D12 + Q20; S-4 → D10; S-5 → D11; S-6 → D13; S-7 → D14; S-8 → D14.

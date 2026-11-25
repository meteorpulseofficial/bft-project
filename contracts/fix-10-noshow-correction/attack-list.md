# Fix #10: checker's pre-mortem (2026-11-24, verbatim in substance)

Probes: scratchpad/f10/repro.sql and self.sql on base (0001–0017).
Hole: set_attendance (0017 ~l.377) deletes only UNDECIDED absences on attended/late. A DECIDED
absence (invalid or valid) stays: strike and booking pause stay; flipping back to no_show reuses the
old decision with no new notice; the Owner/GM path on a verified class has the same hole. A manager
who is also a coach can set_attendance on their own position (verified_by = themself) and wipe their
own undecided no-show.

A-01 manager, unverified class: no_show → decided invalid → attended → refused (D3); admin: absence
gone, strike −1, paused false, claim works. Undecided path for a manager: removed.
A-02 same corrected to late (minutes_late kept).
A-03 decided valid then attended → removed (admin), no unpaid wording left.
A-04 undecided, answered on time with evidence, then attended → removed, correction notice,
evidence path recorded.
A-05 undecided overdue unanswered (auto-strike), then attended → strike gone.
A-06 verified class, manager corrects → exact fix #4 refusal, nothing changed.
A-07 verified class, Owner and GM each correct → strike gone, class stays verified.
A-08 manager-coach corrects own position (undecided and GM-decided) → refused (D4); inactive manager /
other-studio manager → 42501.
A-09 coach, Finance, anon, service_role call set_attendance → refused, no change (state what
service_role does today and keep it).
A-10 attended → no_show again after removal → new row, new due_at, decision null, one notification.
A-11 no_show → no_show with a decided row → no change, no notification.
A-12 correction when no absence exists → no notification, no error.
A-13 two-strike pause lifted by correcting one → paused false, strikes_cleared_at unchanged,
"Booking is open again." present.
A-14 coach at two studios → the other studio's strike_count unchanged.
A-15 outside-window / forgiven absence corrected → removed; notice has no strike claim beyond D6.
A-16 assign_position(NULL) after start with a decided absence → asserted as staying (D8).
A-17 set_class_cancelled after a decided no-show → current behaviour asserted.
A-18 race correction vs decide, both orders, two real sessions → consistent, D9 text.
A-19 race correction vs submit_absence.
A-20 race two admins attended vs no_show → attendance and absence agree.
A-21 invariant after every test: no attended/late position with a live absence (except D3 refusals,
where attendance did not change).
A-22 not applicable (delete, not void).
A-23 catalog: definer, search_path, grants, no overloads, new table locked down, lock text not one
literal.
A-24 migration: 0018 on a db at 0016 aborts; second apply same line, fingerprints unchanged;
0010/0012 re-run no change; 0016 refused; 0017 per D11; baseline line false before / true after.
A-25 result line exact counts on seeded stale rows (attended+invalid, late+valid,
attended+undecided), same on re-run.
A-26 full run.sh + fix8_apply, fix8_race, fix9_apply, fix10_apply, run_scenarios all pass.
A-27 session TZ UTC, Asia/Kuala_Lumpur, America/New_York → same; notice uses studios.timezone.

Coverage map: see CONTRACT.md "Acceptance tests (where)"; every check id in 99c starts with its
A- number (A01-…, A27-…; D9-… = A-18/A-19 sequential halves; C0n = A-23).

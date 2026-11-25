# Fix #9: checker's pre-mortem (2026-11-24 01:45 UTC, verbatim in substance)

Probes: scratchpad/fix9/repro.sql, probe2.sql, probe3.sql on chk_fix9_pm (0001–0016).
Hole: classes 100 and 200 days old marked no-show today and decided invalid → strike_count 2,
booking paused, claim refused; coach told "Reply by …" and "This counts as a strike." twice.
P1: after marking, a manager can move an unverified class's starts_at (+400 days) or cancel it; the
absence stays. P5: now() − make_interval(days => N) shifts by an hour under a DST session time zone.
D2 probe: absence recorded before resume, decided invalid after → 0 strikes but coach told "This
counts as a strike."

A-01 class 100 d ago marked today: unanswered/invalid/late → 0. A-02 class 10 d ago invalid → 1.
A-03 boundary at exactly window (counts) vs −1 µs/−1 s (not), under UTC, KL, New York (DST).
A-04 30-day studio: 40 d → 0, 29 d → 1; other studio unaffected. A-05 two studios independent.
A-06 23:30 KL last day of month drops at 23:30 KL; no ::date / at time zone in strike_count.
A-07 Owner changes window 90→30 lifts pause; 30→90 brings back strikes (document).
A-08 class moved to the future after marking must not extend the strike. A-09 class moved 200 d
into the past after marking must not erase the strike (manager could wipe own strike). A-10
Owner/GM edits starts_at on a verified class: define effect.
A-11 resume at T: marked after T for class before T → counts; before T → not; exactly T → counts.
A-12 pending at resume, decided invalid after → 0 but message promises a strike. A-13 re-mark game
(attended → no_show after T) counts again and resets due_at — document. A-14 admin edit of a decided
absence doesn't change created_at.
A-15 frozen clock +6 d unpauses a coach (strikes from classes 85 d ago); claim works. A-16 reverse
only if starts_at moved forward; result line counts it. A-17 manager page and claim agree.
A-18 fix #8 holds in window. A-19 decide/submit on out-of-window absences still work, count 0.
A-20 absence with missing position/class (session_replication_role replica) → not counted, no
error. A-21 studio mismatch (postgres only) → document. A-22 class cancelled after no-show → still
counts (unchanged, record).
A-23 result line exact counts (stop counting / start counting / unpaused / paused), same on re-run.
A-24 precondition: 0017 on a db at 0015 aborts. A-25 definer, search_path, grants (no anon), one
overload; re-running 0010/0012/0016 after 0017 (0016 re-run restores old body — decide); baseline
line true only after 0017. A-26 end-check compares strike_count with the written-out rule. A-27 full
runner, scenarios, fix8_apply.sh, fix8_race.sh. A-28 anon can't execute.
A-29 app labels "counts as a strike" / "Strike" are false for out-of-window absences.

Spec problems SP-1..SP-9 → v2 (CONTRACT.md).

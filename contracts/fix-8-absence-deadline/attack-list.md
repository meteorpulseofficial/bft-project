# Fix #8: checker's pre-mortem (2026-11-24 00:59 UTC, verbatim in substance)

Probes: scratchpad/fix8/repro.sql, selfdecide.sql on chk_fix8_base (0001–0015).
F1 (blocks): overdue coach submits → accepted, submitted_at late, strike_count 2→1, booking_paused t→f,
manager notified. F2: manager who also coaches at the studio can decide own absence valid, and flip an
already-decided invalid to valid (decide_absence checks only manages_studio). F3: anon can call
strike_count / booking_paused (grants include anon and PUBLIC on all five absence functions).

A-01 submit 1 s before due → saved, notified, no strike. A-02 due_at = now() same txn → allowed (guard).
A-03 due − 1 µs / − 1 s → P0001 D1 text, row byte-identical, no notification. A-04 on-time answer
re-submitted after due → refused, original kept. A-05 overdue + bad reason/empty explanation →
deadline message (order: not found → decided → deadline → reason → explanation). A-06 overdue +
decided → "already decided". A-07 message reaches app clean. A-08 session TimeZone KL vs UTC same;
no ::date / at time zone in 0016. A-09 txn starts before due, commits after → allowed, consistent.
A-10 due_at stays not null.
A-11 old late row counts; 2 → paused, claim refused, swap_target_blocker blocks. A-12 outside window
or before strikes_cleared_at → 0. A-13 submitted_at = due_at → no strike. A-14 answered on time, now
past due, undecided → no strike. A-15 late row decided valid → 0, invalid → 1. A-16 resume_booking →
0; new late row after counts. A-17 two studios independent.
A-18 manager decides overdue/late rows → works, coach notified. A-19 other-studio manager / coach /
finance / anon → refused. A-20 self-decide (F2). A-21 locked class not yet due → submit/decide work
(test 96 D9). A-22 locked + overdue → deadline message. A-23 re-marking no_show → attended → no_show
recreates the absence with a fresh due_at (deadline reset) — record.
A-24 other people calling submit_absence → "Not found." regardless of state. A-25 grants after 0016
asserted (F3). A-26 p_evidence pointing at another coach's file → accepted (out of scope, record).
A-27 app uploads evidence before the RPC → orphan MC photo after refusal (needs staging Storage).
A-28 refusal → no notification rows.
A-29 0016 twice → no-op, same md5(prosrc), same result line. A-30 one begin/commit; applies via
ops/migrate.sh local; add ops/baseline-checks.tsv line. A-31 result line counts only. A-32 full
suite, scenarios, ops kit tests, 60/96 green.
A-33 coach page overdue → no form, message wraps at 390px. A-34 server clock behind DB → refusal
shown in form. A-35 app overdue = due < now; pure function in src/lib with frozen-clock tests.
A-36 /shifts banner still says "Reply by <past date>". A-37 manager page: late row under "To review"
with "answered late". A-38 manager page: overdue-unanswered rows only in History, no buttons.
A-39 "Booking paused" list reflects A-11.

Spec problems S1–S7 → v2 (CONTRACT.md).

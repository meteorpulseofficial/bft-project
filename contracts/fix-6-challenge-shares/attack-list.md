# Fix #6: checker's pre-mortem attack list (2026-11-22 00:42 UTC, verbatim in substance)

Probes: scratchpad/fix6/p1–p4.sql, proto.sql, race.sh on chk_fix6 (0001–0014).
Holes today: H1 manager inserts 60/40/50 → saved, 7500 from 5000 pool. H2 one PATCH sets every share
to 100 → 300%. P2 33.333×3 on 500 → 500.01. H4 (out of scope) non-member can be a challenge coach.

Findings vs draft v1: F1 two concurrent saves can each pass a deferred check (200%) — lock the
challenge row FOR NO KEY UPDATE (blocks). F2 3-decimal % that must total exactly 100 + round-down
cannot give 833.33 × 3 (golden month line 6, pay spec R-40) (blocks). F3 float round-down in the app
preview disagrees with the DB (1.14% of 10000@50% → 56.99 vs 57.00); x*1000 not exact; >2^53 above
~RM90k in whole units. F4 extra decimals silently rounded by numeric columns; "0x32" = 50.
F5 edits to an existing bad challenge refused with a confusing message.

A-01 one insert 60+40+50 as manager → 23514, no rows; app deletes the challenge.
A-02 50/30/20, 33.333×3 split, 100, 0.001+99.999 → saved; amounts exact per formula.
A-03 totals 99, 101, out of tolerance → refused; message shows the total to 3 decimals.
A-04 one-row UPDATE breaking the total (autocommit) → refused.
A-05 two UPDATEs in one transaction keeping 100 → allowed; one UPDATE of all rows → allowed.
A-06 upsert breaking the total → refused; keeping it → allowed.
A-07 move a row to another challenge → refused if either side breaks; both fixed in one txn → allowed.
A-08 delete 1 of 3 → refused; delete all rows / the challenge / the studio (cascades) → allowed.
A-09 delete a profile with challenge rows → FK error as today, not hidden by the new message.
A-10 TRUNCATE leaves zero rows (allowed). Note anon/authenticated hold TRUNCATE (separate item).
A-11 concurrent inserts/moves on the same challenge → second waits or is refused.
A-12 SET CONSTRAINTS IMMEDIATE + rollback to savepoint → still refused at commit.
A-13 check is security definer, search_path=public, locks the parent row, not executable by clients.
A-14 service_role/postgres refused; only DISABLE TRIGGER / replication role bypass (owner/superuser).
A-15 deferred error not catchable in plpgsql; tests use SET CONSTRAINTS <name> IMMEDIATE to assert.
A-16 share 0.0004 → old per-row 23514 with a different message; app must not branch on errcode alone.
A-17 revenue 0 / coach_pct 0 → all 0.00, total rule still applies.
A-18 pool not a whole sen → Σ amount ≤ floor(pool to sen); leftover < n sen.
A-19 revenue/coach_pct change → recalculated with the new rule; same-value update still recalcs.
A-20 edit of a challenge that already breaks the rule → behaviour decided and tested.
A-21 touching an old row re-rounds it with the new rule (state it).
A-22 coach row for a missing challenge → old FK error.
A-23 re-run 0015 twice (DROP TRIGGER IF EXISTS + CREATE CONSTRAINT TRIGGER; no OR REPLACE); one trigger; result line each run.
A-24 0015 with bad data present → succeeds, counts reported.
A-25 re-run 0010/0012 after 0015 pass; new function must not name studios/checkin_token, no EXECUTE.
A-26 tests 40 and 70 fixtures still pass unchanged.
A-27 extra_earnings columns/types unchanged.
A-28 app server: share strings ^\d{1,3}(\.\d{1,3})?$, ≤100; total rule in whole thousandths; "99.96", 4 decimals, "1e2", "0x32" refused before any insert.
A-29 app preview matches DB: 10000/50%/1.14 → 57.00; 5000/50% even 3-way → 833.33; RM 9,999,999.99 no precision loss; coach % / revenue with too many decimals refused.
A-30 Split evenly for n = 3,6,7,9,11,13,17,30,99 passes the total rule.
A-31 app shows the DB message when the DB still refuses; no challenge left behind.
A-32 hosted (demo) through supabase-js: 60/40/50 insert returns an error (code 23514), no 2xx, rows absent.

Spec problems → v2: 1 (F2) → D3; 2 rounding direction → D4 + Q-5 note; 3 old rows → D5; 4 (F1) → D1;
5 errcode → D1/D7; 6 → R-14; 7 → D7; 8 → R-05; 9 → R-12..R-16; 10 → D8.

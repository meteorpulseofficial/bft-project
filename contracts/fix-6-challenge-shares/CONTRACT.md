# Fix #6 (Challenge shares can add up to more than 100%): contract

**Version:** 2.1 · **Frozen:** v2, 2026-11-22, by Claude as Aaron's IT (technical calls delegated) · **Owner:** the db lane (+ small app half) ·
**Last changed:** 2026-11-22 · by Claude as Aaron's IT (technical calls delegated; pay rules to Kelvin)

## What changes (for Kelvin)

An 8 Week Challenge splits a coach pool (revenue × coach %) between coaches by share %. Today the
database accepts shares that add up to anything: we saved 60 + 40 + 50 and paid RM7,500 out of a
RM5,000 pool. Rounding each coach's amount up also pays out more than the pool (three shares of
33.333% total RM500.01 from RM500.00). After this fix a challenge's shares must add up to 100%, and the payouts never add up to more than the pool. Any sen left over from rounding stays
unallocated until you answer pay question Q-5 (who gets the leftover sen).

## Today's paths

- `challenge_coaches` (0005:28): `share_pct numeric(6,3)`, each row checked 0 < x ≤ 100, no total check.
- `challenge_coach_amount` trigger (0005:37, definer): `amount = round(revenue * coach_pct/100 * share_pct/100, 2)` — half-up, can overpay.
- `challenge_recalc` (0005:50): on challenges revenue/coach_pct update, touches every coach row.
- RLS: `challenge_coaches_write` / `challenges_write` = studio manager (incl. Owner/GM via manages_studio).
- App: `createChallenge` (app/src/app/manage/extras-actions.ts:25) inserts the challenge, then all coach
  rows in ONE insert request; on error it deletes the challenge. No edit path; delete = whole challenge.
  ChallengeForm.tsx warns in red only when |total−100| > 0.05 and still lets you save.
- `extra_earnings` view reads `challenge_coaches.amount`.

## Decisions (orchestrator, v2 — after the checker's pre-mortem, `attack-list.md`)

- D1. **Total rule.** For every challenge that has at least one coach row, the shares must add up to
  100%, allowing only the rounding of 3-decimal shares: `abs(sum(share_pct) - 100) <= 0.0005 * n`
  (n = number of coach rows). So 33.333 × 3 (99.999) and 14.286 × 7 (100.002) pass; 99, 101, 150 are
  refused (pay spec R-42). Enforced at commit by a DEFERRABLE INITIALLY DEFERRED constraint trigger on
  `challenge_coaches` (insert / update / delete), so a whole split can be written in one statement or one
  transaction. Zero coach rows is allowed (the app creates the challenge first; cascade deletes pass).
  The check function is security definer, `search_path = public`, locks the challenge row
  `FOR NO KEY UPDATE` before summing (checker F1: concurrent saves), and is not executable by
  anon/authenticated. Applies to everyone incl. postgres/service_role (data rule; only DISABLE TRIGGER or
  replication role get round it — owner/superuser, not any API path). Refusal: errcode 23514, message
  built with `format()`: "Challenge shares must add up to 100%. They add up to <x.xxx>%."
  An existing challenge that already breaks the rule cannot be edited unless the write brings it back
  within the rule (the check judges the state at commit): edits that leave it broken, incl. the
  revenue/coach % recalc, are refused with the same message; repairing the split in one statement or
  transaction, or deleting the challenge, is allowed (checker F5; db lane point 1, accepted v2.1).
  The check also touches the challenge row (`update … set id = id`) so REPEATABLE READ races fail
  with 40001 instead of both saving (db lane point 2, accepted v2.1).
- D2. A `challenge_id` move is checked for both the old and the new challenge.
- D3. **Payout maths (checker F2).** Shares are treated as weights of the pool:
  `amount = floor(revenue × coach_pct / 100 × share_pct / Σ share_pct × 100) / 100` (round down to
  the sen; Σ over that challenge's rows). Equal shares therefore always pay `floor(pool / n)` — RM2,500
  three ways = 833.33 each, 1 sen left over (pay spec R-40, golden month line 6). 50/30/20 pays exactly
  50/30/20. Payouts never add up to more than the pool. Because each amount depends on the whole split,
  amounts must be correct after commit for every row of every touched challenge (the db lane designs how:
  e.g. the commit-time trigger recomputes the challenge's rows; mind trigger recursion and the old
  per-row amount trigger). Revenue/coach % changes recompute too.
- D4. **Leftover sen** (< n sen per challenge) is given to nobody, pending Kelvin's **Q-5**. Rounding
  down instead of half-up is itself an interim pay choice; it is listed next to Q-5 for Kelvin.
- D5. Existing rows are not rewritten (money may already have been paid at the old amounts). Touching a
  row recomputes its challenge with D3. 0015's result line reports three counts: challenges whose shares
  break D1; challenges whose Σ amount exceeds the pool; coach rows whose stored amount differs from D3.
- D6. Migration 0015, one transaction, re-runnable (DROP TRIGGER IF EXISTS + CREATE CONSTRAINT TRIGGER);
  every earlier test, scenario and fix #1–#5 guarantee keeps passing; 0010 and 0012 re-run after 0015
  still pass (new functions don't name studios or checkin_token, no EXECUTE); `extra_earnings` shape
  unchanged.
- D7. **App half.** `createChallenge` (server) and ChallengeForm:
  - share % as a string matching `^\d{1,3}(\.\d{1,3})?$`, > 0, ≤ 100; coach % and revenue at most 2
    decimals; hex / exponent / extra decimals refused, never silently rounded;
  - the total rule of D1 in whole thousandths (integers, no float tolerance; today's 0.05 removed);
  - "Split evenly" gives every coach the same share (round(100/n, 3)) so equal splits pay floor(pool/n);
  - the amount preview uses D3 in integer maths (BigInt or equivalent, exact up to RM 10,000,000);
  - Save disabled with a clear message while the rule fails; if the database still refuses, its message
    is shown and no challenge is left behind. The app never branches on errcode alone.
- D8. Out of scope, recorded: which profiles may be challenge coaches (a non-member can be added today —
  a cross-studio payout path for Stage 3); locking a challenge once its month is paid (Stage 3);
  TRUNCATE grants (separate hardening item).

## Acceptance tests

- R-01 insert 60 + 40 + 50 in one statement → refused 23514, nothing saved (manager, PostgREST style).
- R-02 50 + 30 + 20 on a 5000 × 50% pool → 1250.00 / 750.00 / 500.00.
- R-03 shares totalling 99% or 101% → refused (pay spec R-42); message shows the total.
- R-04 33.333 × 3 on a 1000 × 50% pool → 166.66 each; Σ ≤ 500.00.
- R-05 revenue 5000, coach 50%, 33.333 × 3 → 833.33 each, Σ 2499.99 (pay spec R-40, golden month).
- R-06 one coach's share updated so the total breaks → refused; all shares changed in one statement or
  one transaction keeping the rule → allowed, amounts recomputed for every row.
- R-07 delete one coach of three → refused; delete the challenge, the studio, or all coach rows → allowed.
- R-08 revenue / coach % change → every amount recomputed with D3; Σ ≤ pool.
- R-09 service_role/postgres also refused when the total is wrong.
- R-10 concurrent saves into the same challenge cannot both pass (A-11).
- R-11 upsert and challenge_id moves follow the rule for both challenges (A-06, A-07).
- R-12 an existing bad challenge: edits refused, delete allowed; 0015 runs with bad data present and
  reports the three counts (A-20, A-24).
- R-13 full suite incl. 40/70/80/90/95/96/97 and scenarios passes; re-runnable; one transaction;
  `extra_earnings` columns unchanged.
- R-14 hosted demo through supabase-js: a bad split returns an error (code 23514) and saves nothing.
- R-15 App: Save disabled and a clear message when the rule fails; preview amounts equal the database's
  for A-29's cases; Split evenly passes for n = 3…99.

## What must NOT change

Creating a challenge with a normal split from the app; deleting a challenge; who can read/write
challenges; the extra_earnings view's shape; every earlier fix.

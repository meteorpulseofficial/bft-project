# Fix #2: checker's pre-mortem attack list (2026-11-21 04:57 UTC, verbatim in substance)

Probe: scratch DB chk_fix2pre (0001–0008), simulated 0010 in a rolled-back transaction.
Probe script: /private/tmp/claude-501/-Users-aaron--claude-spares-spare-QytjzX/68c4a019-1723-415b-9c7e-1765be11cbdd/scratchpad/probe2.sql

## Probe results (simulated 0010)
- Coach filtering/ordering on a pay column → 42501 (before any row is read). count(*) works; `select *` and `to_jsonb(s)` → 42501.
- Coach logging/editing PT with today's pt_guard → 42501; manager logging PT with coach_pct null → 42501. pt_guard must change.
- Owner `update ... where id=` works; `returning id` works; `returning lead_rate` 42501; `where lead_rate is null` 42501; `insert ... returning id` works; GM `insert ... select` (test 30 shape) works.
- Owner upsert `on conflict do update set pay_col = excluded.pay_col` → 42501 (EXCLUDED needs SELECT). Upsert of non-pay only works.
- Manager inserting a challenge (FK to studios) works. service_role keeps table SELECT. anon count(*) → 42501.
- Today, must stay: T2 coach moving own pending PT to a studio they're not in fails 23502 (coach_pct null) — only blocked by accident, `pt_update` WITH CHECK has no membership test. T3 coach with inactive membership editing own pending PT fails 23502.
- An inactive-profile manager with an active manager membership gets manages_studio() = true.

## Read paths into studios
- Security invoker (breaks after 0010): only `pt_guard` 20260927000005:95 (privileged branch, only when coach_pct null) and :99 (coach branch, every insert/update). touch_updated_at reads nothing. No view, RLS policy or storage policy reads studios.
- Security definer (unaffected): generate_classes 0001:293, check_assignable 0006:39, drop_position 0006:73/0007:187, fmt_class 0007:104, strike_count 0007:114, booking_paused 0007:125, swap_blocker 0007:146, respond_swap 0007:252, check_in 0007:359, set_attendance 0007:435, verify_class 0007:471.
- App reads naming a pay column or `*` (4): admin/page.tsx:7 (Finance lands here too, src/app/page.tsx:7); admin/studios/[id]/page.tsx:11; manage/[studioId]/pt/page.tsx:31; manage/[studioId]/challenges/page.tsx:26.
- App writes: admin/studios/actions.ts:86 (update), :89 (insert .select("id")); qr/actions.ts:12; extras-actions.ts:96 logPt (coach_pct null → pt_guard stamps; manager logging for a coach → approved) and :121 reviewPt.

## ATTACK LIST

### db lane
- A-01 Each coach role in the 70 seed (ptl, pt2, ft, sbj, inp, inm, rm, mc-as-coach) selects each pay column alone, `*`, whole row `to_jsonb(s)`, a filter on a pay column, an order by a pay column → 42501 every time, not 0 rows (R-01, R-04).
- A-02 Same for mgrB, mgrS, mcs, mc, xmgr → 42501 (R-02).
- A-03 Same for own, gm, fin, finc → 42501 (R-03); also `update ... returning <pay col>` → 42501.
- A-04 Catalogue check: every non-pay column has has_column_privilege('authenticated',…,'SELECT') = true, every pay column false; a new column in neither list fails the test (drift guard). Also has_table_privilege authenticated/anon SELECT = false; anon has no column SELECT; service_role keeps table SELECT; information_schema.column_privileges shows no leftover pay-column grant.
- A-05 The 70 matrix treats 42501 and 0 rows alike, so cannot prove R-01–R-04; a separate test must assert sqlstate 42501.
- A-06 studio_pay_settings() for all 18 matrix roles plus auth.uid() null: own, gm, fin, finc → 3 rows with seeded values (BGS 80/50/50/50/support, SBJ 75/45/40/55/lead, KLC 90/60/45/60/support — verify against the seed); everyone else (incl. xgm, inp, xmgr) 0 rows no error; p_studio=KLC → 1 row for admin/finance; random uuid → 0; studio caller can't see → 0.
- A-07 studio_default_splits(p): mgrB on BGS 1 row, on SBJ/KLC 0; mc on KLC 1 row, on BGS (only coach) 0; mcs on SBJ 1; xmgr on SBJ 0; inm on BGS 0; own/gm/fin/finc any studio 1; p_studio null 0 for everyone; inactive-profile manager with active membership → 0 (contract v2 D7; add this role to the test).
- A-08 Grants on both functions and the pt_guard helper: anon EXECUTE false, public false, authenticated true. The local stub gives anon EXECUTE on new functions by default (00_supabase_stub.sql:8) like hosted Supabase; revoking only from public leaves anon with EXECUTE.
- A-09 pt_guard coach path after 0010: ptl inserts at BGS with coach_pct=100, status approved → 50, pending (test 40:38–41). pt2 inserts at BGS then SBJ → 50 then 55.
- A-10 Coach moves own pending session to another studio (ptl BGS→SBJ, BGS→KLC) → fails as today (T2, 23502), stored coach_pct and studio_id unchanged.
- A-11 Coach error oracle: insert/update against SBJ vs KLC give the same sqlstate and message.
- A-12 inm with a pending PT session edits it after 0010 → fails as today (T3). rm deleting an old pending row still works.
- A-13 pt_guard helper called directly by a coach (/rpc, pg_graphql) for another studio → null. Own studio: allowed per contract v2 D8.
- A-14 pt_guard must stay security invoker with its current_user check (if definer, current_user is always postgres and every coach self-approves). Test 40:40–41 catches it; keep it.
- A-15 pt_guard privileged branch, coach_pct null, after 0010: mgrB inserts approved session for ptl → BGS default (logPt path); Owner and GM for BGS and KLC; postgres and service_role inserts → default (a helper checking membership returns null with no auth.uid(), so this branch must read studios directly for them); fin and finc logging own PT → default (a helper reading studio_members directly would break this).
- A-16 R-10: own/gm update all 5 pay cols + a non-pay col where id= → sticks; own insert … returning id ok; gm insert … select ok; mgrB and ptl `update studios set lead_rate=1 where id=BGS` → 0 rows, value unchanged, no error; upsert writing a pay column → 42501 (record it).
- A-17 R-11: 0001–0009 then full suite 10–80 (70 unchanged, #2=44) before 0010; pt_guard identical incl. T2/T3.
- A-18 R-12: 0010 then rollback line → old app's four reads work for each role. anon is not restored (0 rows → 42501); matrix treats both as nothing.
- A-19 0009 twice and 0010 twice → re-runnable, grants unchanged.
- A-20 0010 ends with a DO block raising if authenticated still has table SELECT or any pay-column SELECT.

### app lane
- A-21 Grep gate: no `.from("studios").select(...)` or embed `studios(...)` names `*` or any pay column. Today exactly 4 sites.
- A-22 Admin edit page when studio_pay_settings gives 0 rows or an error; Owner saves an unrelated field → stored pay values unchanged (today saveStudio writes all 5 → would wipe to null/50%).
- A-23 Admin home for Owner, GM, Finance: banner lists exactly active studios with null lead or support (fixture as_owner_one_studio_missing_rates); inactive studios left out; on function error, neither "rates not set" for every studio nor silently disappearing — contract v2 D11: show "Pay rates could not be checked".
- A-24 Manager PT page with 0 rows → no "NaN% coach / NaN% studio"; approve/reject still work (reviewPt posts the session's own coach_pct, pt/page.tsx:68).
- A-25 Challenge page with 0 rows → no "NaN" or 0 prefill; empty required field.
- A-26 RPC not called with .single() feeding notFound() (PGRST116 on 0 rows would 404 the page).
- A-27 Owner/GM on /manage/[id]/pt and /challenges for a studio they don't manage → 1 row; Finance redirected before the call (session.ts:55).
- A-28 Display unchanged: "50%", not "50.00%"; PostgREST numeric arrives as a JSON number (fixture v2 shows both). No new float money maths.
- A-29 Insert .select("id") and update (return=minimal) through real PostgREST after 0010 — staging only.

### staging only (CANNOT VERIFY until staging exists)
- A-30 Hosted: A-04 checks hold; studios owner = function owner; revoke grantor matched.
- A-31 PostgREST: `select=*`, `?select=id&lead_rate=gt.0`, `order=pt_coach_pct`, `select=id,lead_rate`, embed `studio_members?select=studio:studios(lead_rate)` → 42501 for coach, manager, Owner; `Prefer: count=exact` works; /rpc/studio_pay_settings reachable after 0009 (schema cache).
- A-32 pg_graphql: studiosCollection leadRate and filters unavailable to a coach.
- A-33 Is studios in supabase_realtime? If so, change events must not carry pay columns.

## Spec problems → orchestrator's decisions (contract v2)
1 inactive-profile manager → D7 (functions require active profile).
2 coach can read own studio's PT % via helper → accepted, D8 (null for non-members; grants).
3 admin edit page wipe → D11 (app already leaves unloaded pay fields alone).
4 banner on error → D11.
5 matrix understated → db lane: split rows 949–950 (checkin_token stays {ALL}, pay cols {} for every role incl. own/gm/fin/finc), flip the 9 open:cover-rule cells to {} and close the tag, move anchors, and 90 covers 18 roles × 2 functions + helper.
6 R-11/R-12 runner → D13; release → D12.
7 fixture strings → fixture v2 + D14.
8 R-09 rewritten (contract v2).
9 R-10 rewritten (0 rows, unchanged).
10 future columns → D10 (drift test + DO block). Fix #3 comes after and will adjust the grant list.
11 pt_update hole → D8 requires null for non-members; policy unchanged in this fix.
12 search_path → D9.
13 the app worktree's supabase/ is stale: the app lane must not run DB tests from it.

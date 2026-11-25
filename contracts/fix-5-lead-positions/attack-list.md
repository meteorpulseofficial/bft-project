# Fix #5: checker's pre-mortem attack list (2026-11-21 12:51Z, verbatim in substance)

Probe: scratchpad/fix5/probe.sql on chk_f5pre (0001–0013).

Holes on current code: P1 decide_swap (0013:408) → do_swap (0013:356) never re-runs swap_blocker: Lead coL requests swap to Lead coT; coT accepts → awaiting_manager; manager sets coT is_lead=false; manager approves → coT in Lead spot, coach_eligible=f (same with membership/profile deactivated meanwhile). P2 manager grants is_lead, assign_position(lead, coS), revokes → coS stays in Lead spot (by design: 0008 members_update, app setLead actions.ts:77). P3 mgrAB (or Owner/GM) `update classes set studio_id=B` on a class with a filled Lead spot → coach not a member of B in its Lead spot (trigger on positions never fires).

Write paths: direct positions_write (invoker, no eligibility — the fix); claim_position (0013:287) yes; assign_position (0013:433) yes (null clears); respond_swap→do_swap yes (swap_blocker on accept); decide_swap→do_swap NO (P1); request_swap no write; drop_position clears; set_class_type (0013:509) only adds/deletes empty spots (lowering lead_positions keeps filled extras); generate_classes empty only; class delete cascade (owner, exempt) removes pay; classes.studio_id/starts_at/status updates (invoker) move/alter positions without touching positions (P3; #13); eligibility changing later (is_lead/active by managers or server key, profiles.active by Owner/GM) (P1, P2). App never writes positions/classes directly.

Manager direct writes
- A-01 mgrA UPDATE coach_id to non-Lead in Lead / studio B coach / non-coach / eligible Lead / null → 42501 "Use Assign…", unchanged. 96 R09-mgr-pos-update (rows:1) flips.
- A-02 UPDATE setting coach_id to its current value plus seq → allowed (IS DISTINCT FROM, null-safe).
- A-03 UPDATE claimed_at or assigned_by alone (incl. null↔value) → 42501.
- A-04 UPDATE role either way, filled and empty; UPDATE class_id to another class at A → 42501.
- A-05 INSERT with coach → 42501; coach null → allowed; coach null with assigned_by/claimed_at → 42501 (D12).
- A-06 DELETE filled → 42501, attendance untouched; empty → allowed.
- A-07 upsert on existing id (insert and update branches) → 42501; upsert clearing a coach → 42501.
- A-08 bulk UPDATE coach_id over studio A → whole statement fails, 0 rows; bulk seq=seq → allowed.
- A-09 verified class coach change → 42501, lock message wins (D10; 96 R08-pos-*, K03/K04).
- A-10 mgrB / coaches on studio A → RLS 0 rows; a coach INSERT hits the BEFORE trigger before RLS WITH CHECK — error must not mention eligibility.
- A-11 xgm (inactive GM) not treated as Owner/GM.
Owner/GM direct writes
- A-12 UPDATE coach_id: non-Lead in Lead → "Lead positions need Lead status at this studio."; studio B coach → "not approved"; non-coach / manager-only / Owner herself → "not approved"; inactive membership or profile → refused; active manager row + inactive coach row → refused; manager row is_lead=true but coach row false → refused for Lead.
- A-13 coach already in that class into a second spot → 42501 one-per-class message, not 23505.
- A-14 role support→lead with non-Lead coach → 42501; lead→support with eligible → allowed.
- A-15 class_id of a filled spot to a studio B class → checked against B; to a class where the coach already has a spot → one-per-class.
- A-16 INSERT with ineligible coach → refused; eligible → allowed.
- A-17 edit non-coach column on an already-ineligible row; bulk over such rows → allowed (D9).
- A-18 correcting a past/verified class with eligible coach → allowed; with a coach who since lost Lead/left → refused (D13).
- A-19 overlapping classes for one coach → refused (D11).
Exemptions / order
- A-20 pg and svc A-01, A-12a, DELETE filled → allowed; FK cascade from class delete works.
- A-21 trigger name order: new must sort after positions_guard_lock (D10).
- A-22 new guard must not exempt is_admin().
Definer paths
- A-23 P1 → decide_swap(approve) refuses with swap_blocker reason; also membership/profile deactivated between accept and approve (D7).
- A-24 respond_swap after target loses Lead → refused (regression). A-25 request_swap to non-Lead / studio B on Lead → refused (regression).
- A-26 claim/assign with non-Lead, studio B, inactive coach → refused, today's text; assign(null) clears.
- A-27 set_class_type lowering/raising lead_positions; generate_classes empty only.
- A-28 P2 → record (D14 out of scope). A-29 P3 → refused (D8). A-30 class delete / direct cancel → out of scope (D14).
Migration
- A-31 0014 twice → same result line; count includes P1/P2/P3-style and legacy rows; one transaction.
- A-32 full run.sh green apart from the 96 rows D2 flips.

Spec problems → v2: S-1 → D13; S-2 → D9; S-3 → D6/D10; S-4 → D11; S-5 → D12; S-6 → D14 + Q21; S-7 → D8; S-8 → D14; S-9 → D7; S-10 → D6 corrected; S-11 → D14.

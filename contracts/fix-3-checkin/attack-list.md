# Fix #3: checker's pre-mortem attack list (2026-11-21 06:37 UTC, verbatim in substance)

Probes (local PG17, chk_fix3_probe*, dropped):
- P1 re-running unedited 0010 after a 0012-style column revoke re-grants checkin_token (its end check passes; grant list 0010:284-289 includes it).
- P2 revoking the column while table SELECT still exists (0012 before 0010) changes nothing.
- P3 fix #2's rollback line (`grant select on public.studios to authenticated`) re-exposes the token after 0012.
- P4 with pgcrypto in `extensions` (as on Supabase — confirmed on the demo 21 Nov), a definer function with search_path public, pg_temp calling bare gen_random_bytes fails "function does not exist"; the column default from 0007 still works (resolved at 0007 time).

## DB lane
- A-01 every role (ptl, pt2, ft, sbj, mc, mcs, inp, mgrB, mgrS, own, gm, fin, xgm, anon) selects checkin_token alone, `*`, `studios(*)` embed, `studios(checkin_token)` embed via classes FK, filter, order, count with filter, `is null` → 42501.
- A-02 Finance (fin, fcA) direct → 42501; studio_checkin_token → null; rotate → 42501, token unchanged.
- A-03 manager of A calls studio_checkin_token(B) → null; mc (coach at B) → null for B, token for A.
- A-04 manager with studio_members.active=false → null / 42501; active manager row but profiles.active=false → null / 42501 (manages_studio doesn't check profile active; D2 needs its own check); inactive GM (xgm) → null.
- A-05 Owner/GM any studio → token; inactive studio → token (check_in rejects it anyway).
- A-06 rotate as Owner/GM with random uuid or null → 42501 (D16), never a token that was never stored.
- A-07 rotate as own manager: new value ^[0-9a-f]{24}$, differs; old token → exactly "This QR code isn't valid any more. Ask your manager for the new one."; new token checks in; check_ins/attendance counts unchanged; only updated_at changes on studios; run with pgcrypto in `extensions` (P4).
- A-08 rotate as coach, other-studio manager, former manager, inactive profile, Finance → 42501 'Not allowed.', token unchanged (compare as postgres).
- A-09 anon no EXECUTE on both (stub 00:8 and Supabase give anon EXECUTE by default; revoke from PUBLIC alone isn't enough); no overloads; prosecdef t; proconfig search_path=public, pg_temp; owner can select checkin_token.
- A-10 order matrix, asserting has_column_privilege for authenticated/anon on checkin_token and the pay columns after each:
  0010→0011→0012→re-run 0010 → hidden; 0011→re-run 0010 (no 0012) → still readable; 0012→rollback→re-run 0010 → defined by D10; 0012 twice → hidden, no error; 0012 at 0009 (P2) or without 0011 → refuses, nothing changed; 0012 after fix #2 rollback → refuses or hides, never "applied but readable" (P3).
- A-11 if 0010 is edited: existing scenarios still pass; its end check still aborts on any other ungranted non-pay column; a new dummy studios column → 0010 and 0012 both abort (D10 grant rule kept).
- A-12 0012 sweeps for invoker readers of checkin_token (functions/views in public) → abort; check_in (definer) not flagged.
- A-13 check_in oracle: valid token for another studio → "No class to check in…", invalid → "isn't valid…" (0007:359-360 vs 368-370); 96 bits, note only; assert no check_ins row on either error path.
- A-14 Owner/GM direct `update studios set checkin_token='1'` still works (UPDATE grant + studios_admin_update 0001:357); accepted in D15, record it.
- A-15 realtime: no publication in repo; demo has 0 rows for studios in pg_publication_tables (checked 21 Nov).
- A-16 tests to rewrite: 60_stage2b.sql:38+68 (token read as authenticated), 90:327 (R05-tok), 90:154/:608 (R05 column list incl. checkin_token), 70:974-982 and c_pin '#3=7'.

## App lane
- A-20 QR page reads only via rpc("studio_checkin_token"); null (deactivated mid-session, etc.) → no QR, no /checkin/null, message shown; printed URL text from the RPC too.
- A-21 rotate uses the user's session client, never lib/supabase/admin.ts; isAdmin early return removed; coach or other-studio manager posting the action with another studio id → DB refuses, message shows; non-uuid studioId → friendly error, not raw 22P02.
- A-22 button for own manager, Owner, GM; others never reach the page; after success the page shows the new code (returned code = re-read code); 42501 shown, not swallowed; 23505 or network error → message.
- A-23 double-tap / two managers rotating at once → never show a code that is already dead.
- A-24 guard catches checkin_token in select, embed, filter, order, insert, update; admin/studios/actions.ts rows never include checkin_token.
- A-25 390px: button + message, no sideways scroll; print layout unchanged apart from the button.
- A-26 confirmation step before rotating.
- (D17) NEXT_PUBLIC_SITE_URL empty → "Site address not set" instead of a relative-link QR (qr/page.tsx:15 base).

## Spec problems → decisions (contract v2)
1 D7 needs 0010 edited → D9. 2 rollback conflicts → D10. 3 pgcrypto schema → D11. 4 tests must be rewritten → D12. 5 Finance with a manager row → D13. 6 "anyone who scanned keeps it" (history, middleware.ts:34 ?next=, Vercel logs) → D14 rotate once at go-live + Q19. 7 no record/notice of rotation → D15 accepted. 8 Owner/GM direct write → D15 accepted. 9 unknown/inactive studio → D16. 10 empty site URL → D17.

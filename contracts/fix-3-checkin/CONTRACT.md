# Fix #3 (QR check-in secret readable by every coach): the contract between lanes

**Version:** 2 · **Owner:** the db lane · **Last changed:** 2026-11-21 · **Frozen:** v2, 2026-11-21,
by Claude as Aaron's IT (Aaron delegated technical calls; product questions go to Kelvin)

## What changes (for Kelvin)

The QR code at each studio is a link containing a secret (`studios.checkin_token`). Today any
signed-in coach can read that secret straight from the database and check in from home, and the
"Make a new code" button only works for the Owner/GM (for a manager it silently does nothing).
After this fix: only that studio's active manager and the Owner/GM can see the code (on the QR
page). A studio's manager can make a new code, and the old one stops working at once. Coaches
can still check in by scanning; nothing else about check-in changes.

**What this fix cannot stop:** a printed QR code can be photographed and shared. Making a new code
(now possible for managers) is the remedy. A code that changes by itself (e.g. shown on a studio
tablet) or a location check would be a new feature: question 19 for Kelvin.

## Decisions (orchestrator, final for v1)

- D1. Same mechanism as fix #2: `checkin_token` comes off the `studios` column SELECT grant for
  `authenticated`. No data moved.
- D2. `public.studio_checkin_token(p_studio uuid) returns text`: security definer, stable,
  `search_path = public, pg_temp`. Returns the token only when
  `manages_studio(p_studio)` (active manager row, or Owner/GM) **and** the caller's profile is
  active; otherwise null, no error. EXECUTE: authenticated only (revoke public, anon).
- D3. `public.rotate_checkin_token(p_studio uuid) returns text`: security definer, volatile, same
  caller rule as D2. Sets a new random token (same format as today: 24 hex chars; see D11 for how), returns it. Not allowed → raises 42501 'Not allowed.' and changes
  nothing. EXECUTE: authenticated only.
- D4. Finance gets the token from neither function (open question 2; nothing in the app shows
  Finance the QR). Fail closed until Kelvin answers.
- D5. `check_in(p_token)` unchanged in behaviour (already security definer). A rotated-away
  token gets today's "This QR code isn't valid any more" message.
- D6. Release, same shape as fix #2: **0011** adds the two functions (no behaviour change);
  app deploys; **0012** removes `checkin_token` from the grant. Rollback of 0012:
  `grant select (checkin_token) on public.studios to authenticated;`.
- D7. Interaction with fix #2: migration 0010 re-grants `checkin_token` when re-run. After 0012,
  re-running 0010 must **not** silently re-expose the token. The db lane picks the mechanism
  (e.g. 0010's grant list and checks made aware of 0012, or 0012's own check plus a test that
  fails if the token is selectable after 0010+0012 in any order) and explains it. 0012 must
  have a precondition like 0010's (refuse unless 0011 is applied correctly) and keep 0010's
  pay-column guarantees intact.
- D8. App: the QR page reads the token via `studio_checkin_token`; the "Make a new code" button
  shows for anyone who can manage the studio and calls `rotate_checkin_token`; success and
  refusal are both shown on screen. No `.from("studios")` select may name `checkin_token`
  (extend fix #2's guard test).

## v2 decisions (after the checker's pre-mortem, file `attack-list.md`)

- D9 (SP1, P1). 0010 **is edited** (unpushed, accepted): when re-run on a database where 0012's
  state is present, it must keep `checkin_token` hidden and its end check must accept that.
  "0012 state present" must be detected so that 0011-only (functions exist, token still
  granted) keeps the token readable (old app still needs it). Db lane designs the marker.
- D10 (SP2, P3). Rollback lines become column-level so they don't undo each other:
  0010 rollback = `grant select (lead_rate, support_rate, lead_covering_support_rate,
  challenge_coach_pct, pt_coach_pct) on public.studios to authenticated;`;
  0012 rollback = `grant select (checkin_token) on public.studios to authenticated;`.
  0010's header and fix #2's contract/PR notes updated to match; tests prove each rollback
  restores only its own columns.
- D11 (SP3, P4). On the hosted demo pgcrypto is in schema `extensions` (checked 21 Nov), so a
  bare `gen_random_bytes` in a `search_path = public, pg_temp` function fails there. Rotate
  uses `set checkin_token = default` (the column default, bound when 0007 ran). Local tests
  must include a scenario with pgcrypto moved to an `extensions` schema.
- D12 (SP4). Tests that read the token as a signed-in user (60_stage2b:38/68, 90:154/327/608,
  70:974-982) are rewritten, not kept passing.
- D13 (SP5). The rule is `manages_studio` + active profile, nothing else: a Finance person who
  also has an active manager row gets their studio's token as its manager; Finance by org role
  alone gets nothing.
- D14 (SP6). Release step added: right after 0012, each studio's manager makes a new code once
  and reprints. That kills every old link in phone history, `?next=` and logs, and every photo.
- D15 (SP7, SP8). Accepted for now: no rotated_at/by record or notice to other managers
  (confirmation step in the app only); Owner/GM can still write a token directly (trusted
  roles). Both noted for Kelvin.
- D16 (SP9). Rotate on an unknown studio or null → 42501 'Not allowed.', nothing returned.
  Admins may rotate an inactive studio.
- D17 (SP10). If `NEXT_PUBLIC_SITE_URL` is empty, the QR page shows "Site address not set"
  instead of a QR with a relative link.
- D18. 0012 refuses unless table-level SELECT on studios is already gone for anon and
  authenticated (P2) and 0011 is correct; it sweeps for invoker readers of `checkin_token`.

## Role table (after 0012)

| role | read token directly | studio_checkin_token | rotate |
|---|---|---|---|
| coach (any) | no | null | refused |
| studio manager (active row, active profile) | no | own studio only | own studio only |
| former manager / inactive profile | no | null | refused |
| Owner, GM | no | any studio | any studio |
| Finance | no | null (Q2) | refused |
| not signed in | no | no execute | no execute |

## Acceptance tests

- R-01 every coach role: select `checkin_token` (alone, `*`, filter, order, embed) → 42501.
- R-02 manager / Owner / GM / Finance direct select → 42501.
- R-03 `studio_checkin_token`: own-studio manager and Owner/GM → the token; other studio,
  former manager, inactive-profile manager, coach, Finance → null; anon → no execute.
- R-04 `rotate_checkin_token` as own-studio manager → new 24-hex token, different from before;
  old token then fails `check_in` with the "isn't valid any more" message; new token works.
- R-05 rotate as coach / other-studio manager / former manager / Finance / inactive profile →
  42501, token unchanged.
- R-06 coach scanning the current token still checks in exactly as today (Kelvin's tests 60 etc.
  still pass); rotation does not touch attendance or check_ins rows.
- R-07 every other studio column still readable as after fix #2; pay columns still hidden;
  70's `#3` pins go to 0 (`c_pin` empty); the `open:manager-token` cells become "via function
  only".
- R-08 0011 alone changes nothing (old app works); 0012 refuses unless 0011 is applied; rollback
  line restores today's reads; both re-runnable; 0012 and 0010 in either order never leave the
  token selectable.
- R-09 App: QR page shows the QR for own-studio manager and Owner/GM; "Make a new code" works
  for them and the page shows the new code; a refusal shows a message; nobody else reaches the
  page (as today).

## What must NOT change

Coach check-in by scan, the 180-minute run, lateness, verification; every fix #1/#2 test; the
printed QR page layout apart from the button and its message.

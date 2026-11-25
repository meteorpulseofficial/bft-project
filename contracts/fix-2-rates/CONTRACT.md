# Fix #2 (pay rates readable by every coach): the contract between lanes

**Version:** 2 · **Owner:** the db lane · **Last changed:** 2026-11-21 · **Frozen:** v2, 2026-11-21,
approved by Claude as Aaron's IT (Aaron delegated technical calls; nothing here is a scope or money decision)

The db lane may fix typos here; a shape change needs the orchestrator. The app lane reads it
and never edits it.

## What changes (for Kelvin)

Today any signed-in coach can read their studio's default Lead and Support rates, the
"Lead covering Support" rule and the PT and Challenge split percentages, straight from the
database (audit #2). Kelvin's plan p3: rates are Owner, GM and Finance only. After this fix:
the pay columns of `studios` can no longer be read directly by anyone signed in. Owner, GM and
Finance read them through one function; a studio manager reads only their own studio's PT and
Challenge default % (their PT-approval and Challenge screens show and use it). Coaches get no rates; they can
look up only their own studio's default PT % (the number on their own PT sessions). All other studio settings (name, timezone, call time, strike rules, ...) stay readable
exactly as today.

## Decisions (orchestrator, final for v1)

- D1. Mechanism: **column privileges** on `public.studios`, no data moved, no columns dropped.
  Revoke table-level SELECT on `public.studios` from `anon` and `authenticated`; grant SELECT on
  an explicit list of every non-pay column to `authenticated`. `anon` gets no SELECT. UPDATE and
  INSERT grants are unchanged (Owner/GM save rates exactly as today through RLS).
- D2. Pay columns = `lead_rate`, `support_rate`, `lead_covering_support_rate`,
  `challenge_coach_pct`, `pt_coach_pct`. `checkin_token` stays readable for now (that is fix #3).
- D3. Two migrations, so the release never breaks a screen:
  - `20260928000009_rates_read_functions.sql`: the two functions below + the `pt_guard` change.
    Changes no behaviour; safe to run any time.
  - `20260928000010_hide_studio_rates.sql`: the revoke/grant. Run only after the app that uses
    the functions is deployed.
  - Release order: run 0009 → deploy app → run 0010. Rollback of 0010:
    `grant select (lead_rate, support_rate, lead_covering_support_rate, challenge_coach_pct, pt_coach_pct) on public.studios to authenticated;` (0009 can stay; column-level since fix #3 contract D10).
- D4. Finance keeps reading rates (open question 2 for Kelvin; today they can).
- D5. Managers see their own studio's PT/Challenge **default %** only, never Lead/Support rates
  or the cover rule. New question 18 for Kelvin.
- D6. A coach logging a PT session still gets the studio's default PT % stamped on their own
  session (they see their own share, which p3 allows). The trigger must keep doing this after
  0010.

## Functions

### `public.studio_pay_settings(p_studio uuid default null)`

`returns table (studio_id uuid, lead_rate numeric, support_rate numeric,
lead_covering_support_rate public.cover_rate, challenge_coach_pct numeric, pt_coach_pct numeric)`

- `language sql stable security definer set search_path = public`.
- Rows only when `public.is_finance_or_admin()`; otherwise **zero rows, no error**.
  `p_studio` null → every studio; else that studio (zero rows if it does not exist).
- Fails closed when `auth.uid()` is null (is_finance_or_admin already does).
- EXECUTE revoked from `public`, `anon`; granted to `authenticated`.

### `public.studio_default_splits(p_studio uuid)`

`returns table (challenge_coach_pct numeric, pt_coach_pct numeric)`

- `language sql stable security definer set search_path = public`.
- One row when `public.manages_studio(p_studio) or public.is_finance_or_admin()`; otherwise zero
  rows, no error. (manages_studio requires an **active** manager row, or Owner/GM.)
- EXECUTE revoked from `public`, `anon`; granted to `authenticated`.

### `pt_guard` (existing trigger function, security invoker)

Both reads of `studios.pt_coach_pct` must work for a coach after 0010. The db lane picks how
(e.g. a security-definer helper that returns the % only to members of that studio), and must
not let the coach set or choose any other studio's %. Behaviour otherwise identical.

## v2 decisions (after the checker's pre-mortem)

- D7. Both new functions also require the **caller's profile to be active**
  (`profiles.active` for `auth.uid()`); an inactive owner/GM/finance/manager gets zero rows.
- D8. pt_guard helper: lives in `public`, EXECUTE revoked from `public`/`anon`, granted to
  `authenticated`. Returns the PT default % **only when `member_of_studio(p_studio)`** (active
  member, or finance/owner/GM), else **null**. It must return null for non-members, because that
  null is what keeps today's T2/T3 behaviour (a coach can't move a pending PT session to a studio
  they're not in; an inactive member can't edit theirs). When `current_user` is postgres /
  service_role / supabase_admin, pt_guard reads `studios` directly (they keep table SELECT).
  pt_guard stays **security invoker** with its `current_user` check. `pt_update`'s policy is not
  changed in this fix.
- D9. New definer functions use `set search_path = public, pg_temp`.
- D10. Every future `studios` column needs an explicit `grant select (col)` in the same
  migration. A drift test (every column is either a pay column with no SELECT, or granted) is
  required, and 0010 ends with a DO block that raises if `authenticated` still has table SELECT or
  any pay-column SELECT. Both migrations re-runnable.
- D11. Admin save never writes pay columns that were not loaded (app: optional pay fields, as
  built). Admin home: if `studio_pay_settings` errors or returns nothing for an admin, show one
  line "Pay rates could not be checked" instead of the banner; never claim all are missing.
- D15 (review 3 follow-up). 0010 starts with a precondition block, before the revoke, that
  aborts with "run 0009 first" (listing what is missing) unless: the three functions exist as
  exact `public.<name>(uuid)` signatures, security definer, with the exact result shapes in this
  contract, `search_path=public, pg_temp`, owned by a role that can read the pay columns,
  EXECUTE for authenticated and not anon/PUBLIC; `pt_guard` is security invoker, wired to
  `pt_sessions_guard`, and its normalised body (comments/whitespace/case stripped) calls the
  helper and reads studios only in the exempt branch — **no exact md5 pin**; and no other
  security-invoker object in `public` (view, function, policy on another table) reads
  `studios` — if any does, abort and list them (protects against production-only objects).
  Result shapes are pinned in both 0010 and 90: a contract change must update both.
- D16. Known limits of 0010's text checks (accepted, review 3 polish): a disguised hand edit
  using `$` inside an identifier (`a$q$`) can hide code from the reader; literal case is ignored,
  so upper-cased role names in pt_guard's exempt branch would pass the check (breaks PT logging
  for the SQL editor / server key, no leak). Both need deliberate SQL-editor edits.
- D12. Release (amended after review 3: two PRs, 5 = db and 6 = app, released together): PR bodies give the order
  0009 → merge/deploy app → 0010. App deployed before 0009 is safe (pages degrade, nothing is
  overwritten); 0010 before the app breaks admin/manager pages, so 0010 is last.
- D13. Test runner: the db lane may add an option to `supabase/tests/run.sh` to stop after a given
  migration and to run a named extra script, for R-11/R-12.
- D14. PostgREST returns `numeric` as JSON numbers; display must stay as today ("50%", not
  "50.00%") whether a number or a string arrives.

## Which role sees what (after 0010)

| role | studios non-pay columns | lead/support rate, cover rule | PT/Challenge default % |
|---|---|---|---|
| part-time / full-time coach | as today (own studios) | none | only own active studio's PT default %, via the pt_guard helper (same number they see on their own PT sessions); never another studio's |
| studio manager | as today | none | own managed studio only, via `studio_default_splits` |
| GM, Owner | as today | all studios via `studio_pay_settings` | all |
| Finance | as today | all (pending Q2) | all |
| inactive person (profile inactive) | as today (open Q12) | none from `studio_pay_settings` / `studio_default_splits` | none from those two; the pt_guard helper still answers for an active membership so their PT logging works as today (open Q12) |
| not signed in | none | none | none |

## What the app lane must not assume

- `numeric` comes back as a string or number from PostgREST; display as today, never do money
  maths in JS floats.
- Zero rows from either function means "not allowed / not found". The screen must still render
  (show "not set" or hide the line), never crash, never hint at the value.
- After 0010 any `.from("studios").select(...)` that names a pay column, or uses `*`, fails with
  a permission error for **everyone**, Owner included. No such select may remain anywhere,
  including embedded selects (`studio:studios(...)`).
- Writes (`update`/`insert` on studios from the admin save action) are unchanged and must keep
  working; their `.select()` after insert may only name non-pay columns (`id`).

## What must NOT change

- Owner/GM: Admin home's "missing rates" banner, the studio settings page loads current rates
  and saves new ones.
- Manager: PT approvals page and Challenge page show the default % and the Challenge form
  prefills it.
- Coach: logging a PT session stamps the studio default %; shifts, slots, absences, PT list and
  every other screen that reads studio settings load as today.
- Kelvin's tests 10–60 and 70/80 pass; in 70 the `#2` pins go to 0 (`c_pin` loses `#2`), `#3`
  stays 7.

## Acceptance tests (R-xx)

- R-01 coach (each coach role in 70) selecting any pay column from `studios` → permission denied.
- R-02 manager selecting any pay column → permission denied.
- R-03 Owner/GM/Finance selecting a pay column directly → permission denied (they use the function).
- R-04 `select *` from studios as any authenticated role → permission denied.
- R-05 every non-pay column readable as before by every role that could read the row (same rows).
- R-06 `studio_pay_settings()` as Owner/GM/Finance → one row per studio with the right values;
  as coach/manager/inactive/anon-with-no-uid → zero rows (anon: no execute).
- R-07 `studio_default_splits(own studio)` as its active manager → one row; other studio → zero;
  former (inactive-row) manager → zero; coach → zero; Owner/GM/Finance → one row.
- R-08 coach inserts a PT session after 0010 → succeeds, `coach_pct` = studio default,
  status pending; coach cannot obtain another studio's % through it.
- R-09 manager / Owner / GM inserting a PT session with null coach_pct (the app's `logPt`
  path) → studio default stamped, approved; postgres and service_role inserts with null
  coach_pct → default; finance logging their own PT → default.
- R-10 Owner/GM update rates and insert a studio (with `.select('id')`) → succeed; manager
  and coach updates → 0 rows, value unchanged (as today, no error). Upsert writing a pay
  column → 42501 (recorded so nobody switches saveStudio to upsert).
- R-11 after 0009 alone (before 0010) the old app still works (no behaviour change).
- R-12 rollback line restores the five pay columns only (column-level since fix #3 D10; it never gives back checkin_token).

## Fixture

`fixture.json` beside this file: example function outputs for the app lane.

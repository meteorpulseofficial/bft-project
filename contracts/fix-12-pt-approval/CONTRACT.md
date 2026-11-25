# Fix #12 (a manager who also coaches can approve their own PT; decided PT can be changed with no record): contract

**Version:** 1 · **Frozen:** not yet (awaiting Aaron) · **Owner:** db lane (app follow-up: bft-builder)
· **Last changed:** 2026-11-25 · by the db lane

## What changes (for Kelvin)

PT sessions are paid from the approved list (extra earnings feed the invoice). Until now a studio
manager who also coaches could log their own PT already approved at 100%, or approve their own
pending one; anyone who could manage the studio could later change the amount, the split, the date,
the client, the coach or the studio of an approved session, flip it back and forth, or delete it,
and nothing recorded who did it.

After this fix:
- **Nobody approves their own PT, except the Owner and the GM.** A studio manager who logs their own
  session gets it saved as pending at the studio's default split (as a coach does). Trying to
  approve, reject or set the split of your own session is refused: "You can't approve your own PT.
  Ask another manager, the Owner or GM." The Owner and the GM may still approve their own; it is
  recorded.
- **A session's coach and studio are fixed once it is logged**: "A PT session's coach or studio
  can't be changed. Delete it and log a new one." (while it is still pending).
- **Approved or rejected sessions are locked.** Managers can't change or delete them: "This PT
  session has already been decided. Ask the Owner or GM to correct it." The Owner or GM may correct
  the status, the amount, the split or the note of someone else's decided session (recorded, with
  their name as reviewer; sending it back to pending clears the reviewer, the history keeps who
  did it); any other change is refused: "Only the status, amount or split of a
  decided PT session can be corrected." Nobody deletes a decided session through the app.
- **Who approved is always the real person.** "Reviewed by", "reviewed at", "created by" and
  "created at" are set by the database; whatever the app sends is ignored. A pending session never
  has a reviewer.
- **Only real, active coaches.** A session can only be logged for someone with an active account
  and an active coach or manager membership at that studio (or the Owner / GM): "That person isn't
  an active coach at this studio." When you log your own session: "Your account is inactive."
  (account switched off) or "You're not an active coach at this studio." Finance staff can log PT only where they are members. A pending
  session can still be approved after its coach has left.
- **Two managers approving at the same moment:** the second is refused (the session is no longer
  pending), so it is approved once, at one split.
- **Every change is recorded** in a new PT history (who, when, before and after), for every insert,
  edit and delete, by anyone including the server. Only the Owner and GM can read it; nobody can
  edit or empty it through the API.
- Coaches: nothing changes in logging PT (still pending at the studio default) or editing / deleting
  their own pending sessions. Totals of approved PT in extra earnings are unchanged.

## Today's paths (base 29b8d2d, 0001–0020)

- The app writes `pt_sessions` directly (no RPC): `src/app/manage/extras-actions.ts` logPt (insert,
  `status: approved` when a manager logs for someone else, `coach_pct: null`), reviewPt (update
  `status` [+ `coach_pct`] `.eq(studio_id)`), deletePt (delete).
- The only guard is trigger `pt_sessions_guard` → `pt_guard()` (0005, rewritten in 0009; security
  invoker; 0010 checks its text). Managers (`manages_studio`) and postgres / service_role pass with
  any value; everyone else is coerced to pending + studio default. RLS (0005): read own / manager /
  Finance-Owner-GM; insert manager or own+`member_of_studio`; update / delete manager, or own while
  pending.
- Findings F1–F7 (attack-list.md): self-approval at 100% (insert, or pending → approved); other
  routes (manage SBJ coach BGS, move studio, reassign coach to self, un-approve / edit / re-approve,
  Owner/GM); decided rows freely editable and deletable with no history; reviewer / creator
  forgeable; managers enter approved PT for non-members, inactive people, Finance; inactive profile
  and Finance (member_of_studio counts Finance everywhere) can log PT; a manager-coach's own
  approval at the studio where they only coach is silently coerced (no error).

## Decisions (orchestrator, final for this fix)

D1–D8 as given by the orchestrator on 2026-11-25 (see the text above); messages exact. Keep the
trigger route (the app's direct writes keep working). D8: no session-date rule, coach_pct stays
0–100 (S-6 / S-7 parked for Kelvin).

## Owner's technical choices (db lane; the orchestrator may overrule)

- T1 **pt_guard() is rewritten in place** (create or replace; same trigger `pt_sessions_guard`,
  BEFORE INSERT OR UPDATE FOR EACH ROW, unchanged). It stays **security invoker** (it tells the
  server key and the SQL editor apart by `current_user`, like every guard since 0008) and keeps the
  exact shape migration 10's text check needs (one read of the studio table, only in the
  postgres / service_role / supabase_admin branch; the default % for everyone else through
  `studio_pt_default_pct`), so 0010 re-run after this file still passes. The same function also
  runs from a new trigger `pt_sessions_guard_delete` (BEFORE DELETE FOR EACH ROW).
- T2 **Order inside pt_guard** (all refusals P0001 unless noted):
  - postgres / service_role / supabase_admin: exactly as 0009 (reviewer stamped from `auth.uid()`
    when the status changes away from pending; % default when null; may insert approved rows with
    reviewed_by null, P-32; may set any column; may delete anything).
  - INSERT: created_by := caller; created_at := now(); reviewed_by / reviewed_at cleared. D5 check
    when the caller manages the studio, or logs for themself and `member_of_studio` (so a plain
    non-member still gets today's RLS refusal 42501, unchanged in tests 40 / 90). Message: coach is
    someone else → "That person isn't an active coach at this studio."; coach is the caller →
    "Your account is inactive." (inactive profile) or "You're not an active coach at this studio."
    (no active coach / manager membership there, not Owner / GM). Then: a manager logging for someone
    else, or the Owner / GM (also for themself), keeps status and %, % default when null, and is
    stamped reviewer if not pending; everyone else (coaches, and a manager logging their own) is
    coerced silently to pending + studio default (R08-04).
  - UPDATE of a decided row (old status approved / rejected): not Owner / GM, or Owner / GM on their
    own row → "This PT session has already been decided. Ask the Owner or GM to correct it.".
    Owner / GM on someone else's row: a change to any column other than status, amount_paid,
    coach_pct, note (id, studio_id, coach_id, client_name, session_date, duration_min) → "Only the
    status, amount or split of a decided PT session can be corrected."; created_by, created_at,
    reviewed_by, reviewed_at sent by the caller are ignored (D4: server-set, kept); % null keeps
    the old %; if status / amount / % / note changed, reviewed_by := caller, reviewed_at := now(),
    else the old reviewer stays; if the new status is pending, reviewed_by / reviewed_at are
    cleared (a pending row never has a reviewer; the history row records who reopened it).
  - UPDATE of a pending row: coach or studio changed → "A PT session's coach or studio can't be
    changed. Delete it and log a new one." (any role, Owner / GM included). created_by,
    created_at and id keep their old values; reviewed_by / reviewed_at cleared. Own row (coach_id =
    caller) and not Owner / GM: status changed, or a % given that differs from the stored one →
    "You can't approve your own PT. Ask another manager, the Owner or GM." (raise, D1/F7: also for
    a plain coach, who was silently coerced before; a manager on own row likewise); otherwise
    coach rules (pending, studio default re-stamped as before, so an inactive member still fails
    NOT NULL as test 90 K08-09/K08-10 expect). Someone else's row, as manager (or Owner / GM, own
    row included): % default when null; reviewer stamped when the new status is not pending.
  - DELETE: decided row → the decided message (Owner / GM included); pending → allowed (RLS as
    before: manager, or own pending).
- T3 **D5 helper `pt_coach_status(p_studio uuid, p_coach uuid) returns text`**: SECURITY DEFINER
  (it must read the coach's profile and memberships whatever the caller's RLS shows), search_path =
  public; EXECUTE for authenticated only (pt_guard runs as the caller), not anon / PUBLIC /
  service_role. 'active' (active profile and org role owner / gm or an active coach / manager
  membership at that studio), 'inactive' (profile inactive or missing), 'not_member'. Returns null
  when auth.uid() is null (signed in with no user id) and unless the caller manages that studio or asks about themself, so it
  tells nobody anything they can't already see. Does not name the studio table.
- T4 **History `public.pt_session_history`** (id bigint identity, pt_session_id uuid not null, no
  FK, op text in insert / update / delete, changed_by uuid (auth.uid(), null for SQL editor /
  server seeds), changed_at timestamptz default now(), before jsonb, after jsonb = the whole row).
  Written by AFTER INSERT OR UPDATE OR DELETE FOR EACH ROW trigger `pt_sessions_history` →
  `pt_session_log()` (SECURITY DEFINER so it can write a table no API role may write; search_path =
  public; EXECUTE revoked from PUBLIC / anon / authenticated / service_role; it can only run as a
  trigger). RLS on; one policy `pt_history_read` (select, authenticated, `is_admin()`). Grants:
  authenticated select only; service_role select only; anon nothing; PUBLIC nothing. BEFORE TRUNCATE
  guard (`guard_truncate`, 0019) on `pt_sessions` and on the history: only postgres /
  supabase_admin may empty them (service_role refused, P-25). Index on (pt_session_id, id).
- T5 **D7 (race)**: no extra lock. An UPDATE of the same row waits on the first transaction's row
  lock; when it commits, Postgres re-reads the row (READ COMMITTED) and the trigger sees OLD with
  the new status, so the second approval is refused with the decided message. Proven with two
  sessions in fix12_apply.sh S3 (and S3-before shows the overwrite at 0020).
- T6 Result line (D8): "PT approvals: managers can no longer approve their own PT, decided
  sessions are locked and every change is recorded. Existing approved sessions whose reviewer is
  their own coach: N; approved sessions with no reviewer recorded: M." Counts only; rows are not
  changed and no history is back-filled; a re-run prints the same counts.
- T7 House style: one transaction; precondition on 0020's marks ("migration 21: migration 20
  (fix #11) must be applied first"); end checks naming the table, its owner and the role running the
  file (staging: a table owned by another role may not take the revokes); re-runnable (create table
  if not exists, create or replace, drop trigger / policy if exists); baseline line.

## Consequences to know (recorded, not decided by the db lane)

- **Re-runs:** re-running 0009 after 0021 brings back 0009's pt_guard (self-approval and decided
  edits open again; the history and delete guard stay); 0021 again restores it
  (fix12_apply.sh S2). Re-running 0010 after 0021 passes its check and changes nothing. The
  ops/migrate.sh ledger never re-runs an applied file.
- **Existing rows** are not changed: old self-approved sessions stay approved and are counted on the
  result line for Kelvin to review; they now count as decided (only the Owner / GM can correct).
- A session the Owner / GM sends back to pending has no reviewer until someone decides it again;
  the history shows who reopened it.
- A coach editing their own pending session gets the current studio default % re-stamped (as
  before); sending a different % is now refused instead of silently reset.

## Acceptance tests (where)

- `supabase/tests/99f_fix12_pt.sql` — 183 checks (14 added in round 2, 3 in round 3), P-01..P-35 db lines (coverage map in
  attack-list.md); every refusal asserts sqlstate + exact message, the row unchanged and no history
  row; every allowed write asserts the history row. On base (29b8d2d, 0001–0020) 140 fail; the
  other 43 pass on base and after (controls: coach logging, approve at a split, reject, manager
  entering for a coach, Finance / coach reach no decided row, seeds, row level security refusals).
- `supabase/tests/scenarios/fix12_apply.sh` — S1 apply on 0020 with seeded rows (counts, rows
  unchanged, baseline false → true, all baseline lines true, re-run identical, 0010 re-run after),
  S2 0009 re-run reopens / 0021 restores, S3 two-session race (P-16) before and after, S4
  precondition at 0019, S5 a database that had round 1's pt_coach_ok: 0021 drops it.
- Existing tests changed (the decisions change these behaviours):
  - 90: R08-05 (inactive profile with an active coach row) and R09-11 (Finance with no membership)
    now refused with the D5 message; R09-09 (Owner logs at a studio with no members) now logs the
    Owner's own session (coA is no coach there, D5), same default-% assertion; R08-06 (coach asks 99% on own pending) now the D1 message;
    K08-02 / K08-08 / K08-06 (coach moves own pending to another studio) now the D2 message; C-08
    lists the new triggers.
  - 70: new relation pt_session_history (Owner / GM all rows, everyone else none; before / after
    sensitive); anchors 44 → 46 columns, 1188 → 1242 cells.
  - 99d C03b: the two new truncate guards.
  - fix11_apply.sh / fix13_apply.sh S1-all-baseline-lines-true: evaluate and count up to their
    own migration (0020 / 0019) only.
- `ops/baseline-checks.tsv` — line for 20260928000021.

## What must NOT change

Coach PT logging (pending at the studio default; tests 40, 90 R08-01..04), a manager approving a
coach's session at a chosen split (R-50 / R-51 / R-54), rejected sessions not in extra_earnings
(R-53), postgres / service_role seeds (ops/seed/data.sql, tests 70, 90), extra_earnings totals in
40 and 70, the read matrix of every existing relation, every earlier test and scenario.

## App follow-up (bft-builder, not db lane)

Shape change for the app: refusal texts and one new readable table (Owner / GM only). The app may
show these seven messages (exact strings): "You can't approve your own PT. Ask another manager,
the Owner or GM." · "A PT session's coach or studio can't be changed. Delete it and log a new
one." · "This PT session has already been decided. Ask the Owner or GM to correct it." · "Only the
status, amount or split of a decided PT session can be corrected." · "That person isn't an active
coach at this studio." · "Your account is inactive." · "You're not an active coach at this
studio." (apostrophes are plain ASCII '). logPt for a manager's own session already sends pending (keeps
working). reviewPt today ignores the error: it should show it. The app may hide Approve / Reject on
the manager's own rows and Edit / Delete on decided rows; the database refuses either way. A PT
history screen for the Owner / GM is optional (columns in T4).

## Open (for Kelvin, via the orchestrator)

- S-6 should PT dates be limited (no future, not older than N days)? S-7 should the split have a
  cap? (parked, D8)
- What to do with the existing self-approved sessions the result line counts.

## Release order

Run 0021 after 0020. No app change is needed for the fix to hold.

## History

- v1 2026-11-25: written by the db lane from D1–D8 and the checker's attack list (P-01..P-36).
- v1 round 2 (still not frozen) 2026-11-25, asked by the orchestrator: created_at server-set on API
  inserts (checker N1); a pending row never has a reviewer, also after an Owner / GM correction
  back to pending (reviewer #2); own-session D5 wording "Your account is inactive." / "You're not
  an active coach at this studio." (checker N5); helper pt_coach_ok renamed pt_coach_status
  (returns the reason). Two new messages for the app.
- v1 round 3 (still not frozen) 2026-11-25, checker findings: pt_coach_status returns null with no
  user id (was answering); 0021 drops a leftover pt_coach_ok(uuid, uuid) and its end checks refuse
  one; fix12_apply.sh fingerprints pt_coach_status (S1-fp21-covers) and has S5. No change for the
  app.

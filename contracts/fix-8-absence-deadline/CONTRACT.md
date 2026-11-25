# Fix #8 (late absence answers remove the strike): contract

**Version:** 2 · **Frozen:** v2, 2026-11-24, by Claude as Aaron's IT (technical calls delegated) · **Owner:** db lane (+ small app half) ·
**Last changed:** 2026-11-24 · by Claude as Aaron's IT (technical calls delegated; rules to Kelvin)

## What changes (for Kelvin)

When a coach no-shows, they get a deadline (5 days) to explain. Missing it counts as a strike.
Today a coach can still send the explanation after the deadline, and the strike disappears at
once — before any manager has looked. After this fix the explanation can't be sent after the
deadline (the coach sees "the deadline has passed, speak to your manager"), and a late answer
never removes a strike by itself. The manager can still excuse the absence (question 27).

## Today's paths

- `absences` (0007:72): writes only via definer functions; RLS has `absences_read` only.
- `submit_absence` (0007:500): checks owner, undecided, reason, explanation. **No `due_at` check**;
  sets `submitted_at = now()`.
- `strike_count` (0007:110): counts `decision = 'invalid'` or `(decision is null and submitted_at is
  null and due_at < now())`, within the window. A late `submitted_at` drops the strike.
- `decide_absence` (0007:518): manager decides any absence, any time (fix #4 keeps it working on
  locked classes).
- App: `src/app/absences/[id]/page.tsx` shows the form whenever undecided (also shows "Deadline
  passed — counts as a strike"); `src/app/shifts/actions.ts:76` calls `submit_absence`; manager page
  `src/app/manage/[studioId]/absences/page.tsx` lists waiting/history by `due_at`.

## Decisions (orchestrator, v1)

- D1. `submit_absence` refuses when `now() > due_at` (P0001 "The deadline to explain this absence
  has passed. It counts as a strike unless your manager excuses it."), changing nothing. At exactly
  `due_at` it is still allowed. Role/ownership refusals keep coming first (no state leak).
- D2. `strike_count` treats an undecided absence as a strike when `due_at < now()` and
  (`submitted_at is null` **or `submitted_at > due_at`**) — so existing late rows, and any future
  path that sets `submitted_at` late, still count. Window logic unchanged (findings #9/#10 are later
  fixes).
- D3. `decide_absence` unchanged: a manager may still mark a late/unanswered absence valid (excused)
  or invalid. Recorded as question 27 for Kelvin.
- D4. Existing rows are not rewritten; 0016's result line reports how many undecided absences have
  `submitted_at > due_at` (strikes that come back after this fix) — so Kelvin can tell coaches.
- D5. Migration 0016, one transaction, re-runnable, applied and tested via `ops/migrate.sh local`
  as well as `supabase/tests/run.sh`; every earlier test/scenario and fix #1–#7 guarantee keeps
  passing (incl. 0010/0012 preconditions re-run, fix #4 lock behaviour of submit/decide).
- D6. App: the coach's absence page hides the form after the deadline and shows the new message;
  if the database refuses (clock skew), the message is shown. The manager page shows "answered
  late" for existing late rows.

## v2 decisions (after the checker's pre-mortem, `attack-list.md`; these win over v1)

- E1 (A-04, A-05, A-06). `submit_absence` refusal order: not found (ownership) → already decided →
  deadline passed → reason → explanation. Re-submitting an on-time answer after the deadline is
  refused and leaves the original answer untouched.
- E2 (S2). The deadline is shown with its **time**, in the studio's time zone, everywhere a coach
  sees it: the no-show notification text, `/shifts` banner, the coach absence page, the manager
  page. `due_at` itself is unchanged (verification time + 5 days). If the notification text is built
  in `set_attendance`, re-create it changing only that text and keep every fix #4 behaviour (tests 96
  must pass unchanged).
- E3 (S3). 0016's result line reports, in the same transaction before/after the change: (a) how many
  absences now count as strikes that didn't, (b) how many coaches become booking-paused. Counts only.
- E4 (S4, F2). `decide_absence`: a manager may not decide their **own** absence (Owner/GM only), and
  a manager may not change an absence that's already decided (Owner/GM may). Role refusals first
  (42501 "Not allowed."); rule refusals P0001 with clear text. Both go to question 27 so Kelvin can
  loosen them.
- E5 (S5, F3). Revoke execute on `strike_count`, `booking_paused`, `submit_absence`,
  `decide_absence`, `resume_booking` from PUBLIC and anon (authenticated keeps what the app uses;
  definer callers like swap_blocker keep working). Update the role matrix test only for this.
- E6 (S1, S6, A-27, A-36–A-38). App: coach absence page hides the form after the deadline and shows
  the message; the evidence upload is skipped when overdue and a file uploaded for a refused answer
  is removed; `/shifts` banner says the deadline has passed; manager page shows overdue-unanswered
  and late-answered rows under "To review" with **Excuse (no strike)** / **Confirm strike** + note
  (existing `decide_absence`); "answered late" label. Deadline logic in one pure function in
  `src/lib` with frozen-clock tests. Release: app first or in the same window as 0016.
- E7. Out of scope, recorded: re-marking a no-show resets the 5-day deadline (A-23; audit #10/#13
  area); `p_evidence` can point at another coach's file path (A-26).

## Acceptance tests

- R-01 coach submits before due → saved, no strike (as today).
- R-02 coach submits 1 s after due → refused P0001, row unchanged, no manager notification.
- R-03 submit exactly at due_at → allowed (boundary, transaction now()).
- R-04 existing row with submitted_at > due_at, undecided → counts as a strike; booking pause
  reflects it.
- R-05 manager decides valid on a late/unanswered absence → no strike; invalid → strike.
- R-06 other coach / manager / anon calling submit_absence on someone's absence → refused as today.
- R-07 fix #4: submit_absence/decide_absence still work on locked (verified) classes.
- R-08 full suite + scenarios + ops kit apply; re-runnable; one transaction; result line.
- R-09 app: overdue page shows the message, no form; refusal message shown.

## What must NOT change

Absences answered on time; manager decisions; strike window and limit maths; booking pause and
resume; every earlier fix.

### v2 acceptance additions
- R-10 refusal order (A-05, A-06); R-11 on-time answer re-edited late refused, original kept (A-04).
- R-12 submitted_at = due_at, and answered-on-time-now-overdue, are not strikes (A-13, A-14).
- R-13 0016 applies via `ops/migrate.sh local`; `ops/baseline-checks.tsv` line added (A-30).
- R-14 locked + overdue → deadline message (A-22).
- R-15 manager deciding own absence → refused; Owner/GM allowed. Manager changing a decided absence
  → refused; Owner/GM allowed.
- R-16 anon cannot execute the five absence functions; authenticated app paths still work.
- R-17 deadline time shown in studio time zone in notification, /shifts, coach page, manager page.

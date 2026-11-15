# <feature>: the contract between lanes

Copy this to `contracts/<feature>/CONTRACT.md` and fill it in BEFORE either lane writes
code. Delete these two lines when you do.

**Version:** 1 · **Owner:** the db lane · **Last changed:** <date> · **Frozen:** no

The db lane edits this file. The app lane reads it and never edits it. After Aaron freezes
it, a shape change needs his yes: bump the version, write it under History, and tell the
orchestrator.

## Tables and columns

| table.column | type | written by | who can read (RLS) | absent / null means |
|---|---|---|---|---|
| `invoice_lines.amount` | numeric(12,2) | verification trigger | coach (own), Owner, GM, Finance | never null once verified |

One row per column the app reads or writes. Nothing appears on screen that is not here.

## Which role sees what

| role | can read | can write |
|---|---|---|
| part-time coach | | |
| full-time coach | | |
| studio manager | | |
| GM | | |
| owner | | |
| finance | | |

This table becomes rows in the role × table test. The checker tests it with RLS on.

## What the app lane must not assume

- Existing rows predate this feature: new columns are null on them.
- Money comes back as a string from `numeric`. Never parse it into a JS float for maths.
- Times are `timestamptz` in UTC; show and group them in Asia/Kuala_Lumpur.
- A row the user may not read is simply missing, not an error. The screen must handle "no
  rows" without hinting that hidden rows exist.

## What must NOT change

Existing behaviour that must stay the same, and how it will be proved (for pay: the
golden month total, to the sen).

## Fixture

`fixture.json`, beside this file. At least:

1. a well-formed row
2. a row from before this feature (new columns null)
3. a malformed row (wrong sign, missing rate, a line with no class)
4. a row the current role must NOT see (to prove the screen never shows it)

## Integration check

The session that finishes second runs it, with both halves on staging:

- [ ] the real migration writes rows on staging
- [ ] the real deployed screen reads them back, signed in as each relevant role
- [ ] an old row still renders
- [ ] a coach cannot see another coach's row

Until all are ticked with a timestamp, the feature is **Done but unverified**.

## Open questions settled here

Every business question this feature depends on (e.g. Q-1 coach vs event rate), with
Kelvin's answer and the date. None open at freeze.

## History

| version | date | what changed | who was told |
|---|---|---|---|
| 1 | <date> | first pinned | — |

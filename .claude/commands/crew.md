---
description: Run a BFT Coach Hub fix, feature or review with a crew: a code owner, an adversarial checker, and you as orchestrator. Asks lane and mode if not given.
argument-hint: "[app|db|review] [bug|feature|review] <what is wrong or what to add>"
---

You are the orchestrator of a BFT Coach Hub crew session. You hold the task, assign file
ownership, route findings, hold the only push/deploy step, and write the session log. You
write no feature code yourself.

This is **client work on Kelvin's codebase** (Studio 613 Sdn Bhd). His repo, his Supabase,
his coaches' data. Default to branches and PRs he merges. Nothing in this session touches
production data.

Arguments given: `$ARGUMENTS`

## 0. Load the map

Read `REPOS.md`, the first 60 lines of `SESSION-LOG.md`, and section 0 of `HANDOVER.md`.
Open items for this lane are context the crew must have.

If `REPOS.md` still says the repo is not cloned, stop: say so, and offer only review of the
`prep/` documents.

## 1. Lane and mode

Parse a lane (`app`, `db`, `review`) and a mode (`bug`, `feature`, `review`). Whatever is
missing, ask with one AskUserQuestion. Lane options come from the REPOS.md table, each with
its one-line description. Mode options:

- **Fix a bug**: starts from a reproduction
- **Add a feature**: starts from a spec Aaron approves before any code
- **Review only**: checker runs, nobody edits

Never guess the lane.

## 2. Pre-flight (read-only, report before spawning)

In the repo: current branch, `git status --porcelain | wc -l`, unpushed count, latest
migration number in `supabase/`, whether staging exists and its URL. List the test kit that
already exists (REPOS.md "Tests" column) so nobody rebuilds it.

**Every code owner gets its own worktree:**
`git worktree add ../.crew-wt/<short-name> -b crew/<short-name> origin/staging`
(or `origin/main` until staging exists, and say so). One PR per change.

**No staging yet?** Then the first job is staging, not features: a `staging` branch with a
Vercel preview, and a second Supabase project seeded with fake data. Until it exists, the
checker can only run against local Supabase, and say `CANNOT VERIFY` for anything that
needs the deployed stack.

## 3. Feature mode: the spec gate

Before any code owner is spawned, write the spec:

- what changes, in one paragraph Kelvin could read
- **numbered acceptance tests** (`R-xx`), input → expected. For pay, start from
  `prep/stage3-pay-spec.md`; for other stages, turn the PDF rules (pp. 3–5) into the same
  form
- what must NOT change
- which open questions (Q-n) it depends on. A rule with an unanswered Q does not get built;
  park it or get Kelvin's answer
- how the checker will prove it

**Then the pre-mortem.** Spawn `bft-checker` in plan mode on the spec (and contract draft).
It returns an ATTACK LIST and SPEC PROBLEMS. Fold spec problems in now.

Ask Aaron to approve **spec + attack list together**, in one AskUserQuestion. No code until
he does.

**Bug mode** skips the approval but not the attack list: spawn the checker first and forward
its list to the owner before the owner hands over.

## 3b. Does it cross lanes?

Most pay work does: a table in `db`, a screen in `app`. If yes:

1. `bft-db` owns `contracts/<feature>/CONTRACT.md` + `fixture.json`, from
   `CONTRACT-TEMPLATE.md`, written before any migration or screen.
2. The checker's pre-mortem covers the contract: every column's absent and malformed case,
   who writes it, which roles can read it (RLS), release order.
3. Aaron approves it. Write `Frozen: v<N>, <date>, approved by Aaron` at the top. After
   that, a shape change needs his yes.
4. Then both halves can run at the same time, in separate sessions and worktrees. The app
   half builds against the fixture.

## 4. Spawn the crew

Both in the background, in one message:

| Lane | Code owner | Checker |
|---|---|---|
| app | `bft-builder`: owns the named files under `app/`, `components/`, `lib/` (confirm in REPOS.md) | `bft-checker` |
| db | `bft-db`: owns the new migration file(s) under `supabase/` | `bft-checker` |
| review | nobody edits | `bft-checker`, all six lenses |

Tell the code owner: the files it owns, its worktree, the approved spec with R-tests, the
attack list, the contract path, the test kit to reuse, and that its first job is tests that
FAIL on the base commit.
Tell the checker: lane, repo, the claim it will receive, the staging target, and to start
mapping attacks while the code is written. It never reads production and never writes.

## 5. The loop

1. Code owner returns `CHANGE / CLAIM / FAILED-FIRST / RAN / NOT RAN / DIFF`. No
   FAILED-FIRST → send it back.
2. In one message, in parallel: forward it to the checker (claim verbatim, diff), **and**
   start a code reviewer on the same diff (`/code-review` or a fresh-eyes reviewer agent).
3. Checker returns `PASS`, `FAIL`, or `CANNOT VERIFY`, having re-run the whole attack list,
   every R-test and every earlier finding.
4. FAIL or blocking review findings: send the owner **all** findings from both in ONE
   message, verbatim (input, expected, actual). No fix suggestions. Back to 1.
5. Three rounds on the same bug: stop and bring the trail to Aaron.
6. CANNOT VERIFY: tell Aaron what could not be tested before anything merges.

Agents cannot message each other. Every hop goes through you, one message per hop.

## 6. Ship

Only after `PASS`:

1. `regression-hunter` for the same pattern elsewhere.
2. Re-run the reviewer only if the diff changed after its last pass.
3. Commit the owner's files only (never `git add -A`), push the `crew/<name>` branch, open a
   PR into `staging`.
4. Verify on the staging preview URL (390 and 1440, marker from the change).
5. **Production needs Aaron's yes, and Kelvin's for anything in his database.** Ask with
   AskUserQuestion: what goes live, to whom, the rollback. For a migration: the exact SQL,
   and that Kelvin (or we, with his written OK) runs it in Supabase. An agent's "ready" is
   not approval.
6. Evidence has a timestamp. Write it down.

Cross-lane features are not done until one session, with both halves on staging, has had
the real migration write rows and the real deployed screen read them back as each role.
Until then: **Done but unverified**.

## 7. Close the session

Append to `SESSION-LOG.md`, newest first, then send the same four sections to Aaron:

```
### <date>: <one-line title>

**Done & verified**: what, who proved it, how, when
**Done but unverified**: what, and what would confirm it
**Needs your approval**: ready, blocked on Aaron (or Kelvin), with the rollback
**Open**: found, not fixed, with the reproduction
```

An empty section is written as "none". The log is the only thing the next session inherits.

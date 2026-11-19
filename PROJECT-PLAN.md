# Coach Hub: project plan, phase by phase

**Confirmed with Kelvin:** 19 Nov 2026. **Price:** RM5,000 build (monthly support fee still
to agree). **Goal:** coaches are paid correctly from Coach Hub, at every studio, without
spreadsheets.

Dates are estimates, assuming we start Mon 24 Nov and Kelvin answers questions within a
couple of days. The pilot has to cover a real month-end pay run, so the finish line depends
on his pay calendar.

## At a glance

| Phase | What | Rough time | Kelvin's sign-off |
|---|---|---|---|
| 0. Kick-off | Agreement, deposit, access, answers | 2–3 days | Signs, pays 50%, gives access |
| 1. Safety net | Test copy, backups, fake data, working tests | 2–3 days | Sees the test copy working |
| 2. Fix the 13 findings | Close the security and data gaps | 4–5 days | Approves going live with the fixes |
| 3. Finish Stage 2 | Claim, check-in, verify, absences tested end to end, on a phone | ~1 week | Tests it on his phone |
| 4. Build Stage 3: pay | Rates, late review, invoices, PDF, bank details, bank file | 2–3 weeks | Tests a full month on the test copy |
| 5. Go live | Release to his real app | 1–2 days | Approves the release |
| 6. Pilot | 3–5 coaches, one real month-end, paid both ways and compared | 1 month-end + a week | Signs off, pays the other 50% |

**Not in this RM5,000** (Stage 4 in his plan, quoted separately later): WhatsApp
reminders, Glofox timetable sync, the owner dashboard.

---

## Phase 0: Kick-off (this week)

**Goal:** everything in place so the team can start without waiting.

| Who | Task |
|---|---|
| Aaron | Send a one-page agreement: scope (phases 1–6), price RM5,000, 50% now / 50% after the pilot sign-off, who owns the code (Kelvin, once paid), what is not included (Stage 4) |
| Aaron | Agree the monthly support fee after go-live (suggest RM300–500 per studio) |
| Kelvin | Pay the 50% deposit (RM2,500) |
| Kelvin | **GitHub:** let us create branches and pull requests on `bft-coach-hub`. He approves every change before it reaches `main` |
| Kelvin | **Vercel + Supabase:** add us as team members, or create the test copy himself and invite us |
| Kelvin | **Upgrade Supabase to Pro** (about US$25 a month, his cost), for daily backups and no pausing. Must happen before any fix goes live |
| Kelvin | Confirm: are migrations 6 and 7 applied on the live database? Any changes since 26 Sep that aren't on GitHub? |
| Kelvin | Answer the pay questions (rates today, month-end and pay date, bank, plus the 9 rule questions in `prep/stage3-pay-spec.md`). Stage 3 needs these by the start of Phase 4 at the latest |

**Done when:** agreement signed, deposit in, access works, Supabase on Pro.

## Phase 1: Safety net

**Goal:** nothing we do can hurt his live coaches.

- **Test copy (staging):** a second Supabase project + a `staging` branch on Vercel with its
  own preview link. Same app, fake data.
- **Fake data:** made-up coaches in every role, both studios, a coach at both studios, a
  Lead, a coach with a strike, a cancelled class. (The `audit-kit/` seed is the start.)
- **Fix Kelvin's tests:** they use fixed September dates and one has failed since ~1 Oct.
  Make them use a fixed clock so they keep passing.
- **Access test:** the role-by-table check from the audit becomes a permanent test, so any
  future change that leaks data fails straight away.
- **Rule from here on:** every change goes branch → test copy → Kelvin approves → live.
  Nobody pushes straight to `main`.

**Done when:** the test copy runs, all tests pass, and Kelvin has clicked around it.

## Phase 2: Fix the 13 findings

**Goal:** close every gap from the audit before pay is built on top.

| Priority | Fixes |
|---|---|
| **First** (data and money) | 1. Managers seeing anyone's private details · 2. Coaches seeing pay rates · 3. Fake-able QR check-in · 4. Verified classes still editable · 5. Non-Leads put into Lead spots · 6. Challenge shares over 100% |
| **Then** (fairness) | Late absence replies removing strikes · deadline counted from the wrong date · strike staying after a correction · full-timers dropping assigned classes · managers approving their own PT · managers editing classes directly · helper functions answering anyone |

**How each fix is done (the crew):**
1. A test that **fails** today, proving the problem exists.
2. The fix, as a new numbered database file (migration 0008 onwards). His existing files are never edited.
3. A separate checker tries to break it, re-running every earlier test too.
4. On the test copy, Kelvin sees it.
5. **Kelvin approves**, then the database change runs on the live system, with a backup taken just before.

**Done when:** all 13 fixed, each with its test, live, and his app works exactly as before for coaches.

## Phase 3: Finish and test Stage 2

**Goal:** the coach loop works end to end, for real people on real phones.

- Run through the whole loop on the test copy: claim → drop / swap → QR check-in → verify →
  no-show → explain → strike.
- **Real phone test:** scan the printed QR with an actual phone camera, and check every coach
  screen at phone size.
- Kelvin's two open Stage 2 decisions: the late grace period (plan says 10 min) and the
  notice needed when the studio cancels a class.
- Test the time edges: classes near midnight, the last day of the month, the 3-hour QR run,
  the 24-hour drop line.

**Done when:** Kelvin and one manager have run a week on the test copy from their phones
and are happy.

## Phase 4: Build Stage 3: pay

**Goal:** a month closes into correct invoices for every coach at every studio.

First, a **frozen spec**: the pay rules as numbered tests, plus Kelvin's answers to the
questions. Then the **golden month**: one month of fake classes, with every coach's invoice
worked out by hand and checked with Kelvin. Every pay change must reproduce it exactly,
to the sen.

Built in this order, each piece tested before the next:

| Step | What | What Kelvin sees |
|---|---|---|
| 4a | **Pay rates**: coach personal rate, special event rate, studio default; pay frozen on a class once it's verified | Rates screen (Owner/GM only) |
| 4b | **Late-pay review**: Owner/GM decides full pay / deduction / no pay per late arrival | Review list |
| 4c | **Invoices**: one per coach per studio per month: classes + challenge share + PT share | Month-end screen with totals |
| 4d | **Invoice PDF + coach confirm / dispute** | Coach sees and confirms their invoice on the phone |
| 4e | **Bank details**: coach enters them, Finance approves changes; stored encrypted, visible to Owner and Finance only | Approval screen |
| 4f | **Bank file**: one file Finance uploads to his bank to pay everyone | Download button |
| 4g | **Change history**: who changed which rate, invoice or bank detail, and when | History screen |

4d, 4e and 4f can be built at the same time once 4a–4c are done.

**Not ours to decide:** LHDN e-invoicing and PERKESO (his accountant), PDPA consent wording
for bank details (his lawyer). We build what they say.

**Done when:** a full fake month on the test copy produces invoices that match the golden
month to the sen, and Kelvin has tested it as Owner, Finance and coach.

## Phase 5: Go live

- Backup taken. Database changes run on the live system with Kelvin's OK.
- App released. Check every screen on the live link, on a phone, as each role.
- Rollback plan written down before release: how to undo it if something looks wrong.

**Done when:** live, checked, nothing broken for current coaches.

## Phase 6: Pilot

**Goal:** prove pay is right with real coaches before everyone relies on it.

- 3–5 coaches + 1 manager at Bangsar use it for a full month.
- **At month-end, coaches are paid the old way as usual.** The app's invoices are compared
  line by line with the old method. Every difference is explained or fixed.
- We support on pay day.

**Done when:** a full month matches, Kelvin signs off, roll out to all coaches, and the
final 50% (RM2,500) is paid. Monthly support starts.

---

## How the team works on every phase

- **One AI builds, a separate AI checks.** The checker can't edit code; it only tries to
  break things and reports. Nothing is "done" until the checker passes it with evidence.
- **Tests first.** Every fix and feature starts with a test that fails, then the code that
  makes it pass.
- **Kelvin approves every live change.** Every push to his `main` goes straight to his
  coaches, so nothing goes there without his yes.
- **Fake data only.** Real coaches' personal and bank details are never used for testing.
- **Every work session ends in `SESSION-LOG.md`** with: done and verified / done but
  unverified / needs approval / open.

## What to do this week

1. **Aaron → Kelvin (today/tomorrow):** a short WhatsApp: "Great to confirm! To start, can
   you: add us to GitHub (branches + PRs), add us to Vercel and Supabase, upgrade Supabase to
   Pro for backups, and send the deposit? I'll send the agreement and the pay questions."
2. **Aaron:** send the one-page agreement and the deposit invoice.
3. **Team:** once access arrives, start Phase 1 straight away.

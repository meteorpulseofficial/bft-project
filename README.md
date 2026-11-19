# BFT Project: team handoff

**Client:** Kelvin Liu, Studio 613 Sdn Bhd (BFT Bangsar; BFT Subang Jaya and Bukit Jalil
coming). **Private repo. Do not share outside the team.** It holds a security review of
Kelvin's live app and his company details.

Last updated: 15 Nov 2026.

---

## Where things stand (read this first)

There are **two deals** with Kelvin, plus one on hold:

| Deal | What | Status |
|---|---|---|
| **1. Coach Hub** | Finish, test and deploy his coach scheduling + pay app | **Agreed in principle:** RM5,000 build + RM25 per new member bonus. Not signed yet |
| **2. Marketing** | Be BFT Bangsar's new marketing agency (ads + content/video) | **Proposal due ~Wed 18 Nov.** Draft ready, needs prices, team names, work samples |
| Hiiiilo | Our WhatsApp AI sales agent | **On hold.** Kelvin not sure yet. Offered only as an optional add-on in the marketing proposal |

### Timeline so far

- **13 Nov:** demo call with Kelvin (Hiiiilo). He sent his Coach Hub build plan and asked us
  to quote to "complete, test and deploy" it.
- **13 Nov:** prepared before seeing the code: pay rules as tests, one coach's October
  invoice worked out by hand, invoice screen mock-up, and our crew working method.
- **14 Nov:** got access to his GitHub repo. Ran a full code review (audit) on a private copy
  with fake data. Never touched his live app.
- **15 Nov:** Kelvin asked if we can help. We replied with the 6-step plan and asked for a
  call. Pricing agreed in principle (below). He then sent his **marketing agency brief**
  and gave us 3 days to send a proposal.

---

## Deal 1: Coach Hub

**What it is:** a phone app for BFT coaches. Part-time coaches claim class spots, check in
by QR at the studio, get verified by the manager, and (once built) get a monthly invoice.
Stack: Next.js on Vercel + Supabase. Kelvin built most of it himself with Claude.

| Stage | Status |
|---|---|
| 1. Logins, studios, timetable, people | Live |
| Extras: 8 Week Challenge, PT split, reviews | Live |
| 2. Claim / drop / swap, QR check-in, verification, absences | Built, in testing |
| **3. Pay: rates, invoices, bank file** | **Not started: our main build** |
| 4. Pilot with 3–5 coaches, WhatsApp, Glofox | Not started |

**Audit result (14 Nov):** a solid base (clean build, security on every table), but **7
things to fix before coaches are paid** and 6 to fix soon. For example: a manager can see
anyone's private details, coaches can read pay rates, QR check-in works from anywhere,
verified classes can still be changed, there's no test copy and no backups.
Full report: [prep/audit-report-2026-11-14.md](prep/audit-report-2026-11-14.md).

**Deal:** shown as a normal project price of RM12,000, reduced to **RM5,000** as a
partnership, plus **RM25 per new paying member** (from his Glofox report). The plan was
also RM1,500/month for support + Hiiiilo, but Hiiiilo is on hold, so **the monthly support
fee is still to agree**.

**Plan to deliver:** fix the 13 findings, set up a test copy + backups, finish testing
Stage 2, build Stage 3 pay, go live, then a 2–3 week pilot alongside his current way of
paying. Nothing goes to his live app or database without his OK.

**9 pay questions for Kelvin** (must be answered before Stage 3):
[prep/stage3-pay-spec.md](prep/stage3-pay-spec.md), bottom of the file.

## Deal 2: Marketing proposal

**His brief:** [prep/marketing/BFT-Bangsar-Marketing-Brief-2026-11-12.pdf](prep/marketing/BFT-Bangsar-Marketing-Brief-2026-11-12.pdf).

**The problem:** RM520/month membership, people compare it with RM180 budget gyms, only
~10% of leads convert, and the sales team can handle only 6–7 leads a day. He wants
education-led content so leads already understand BFT. Current agency leaves end of Dec;
assets are handed over 31 Dec.

**What we offer:** paid Meta ads + content/video. **Not** creators or events (optional,
through a partner). Hiiiilo is an optional add-on.

**Draft:** [prep/marketing/proposal-draft.md](prep/marketing/proposal-draft.md).
Packages: Starter RM4,500 / **Growth RM7,000 (recommended)** / Full RM9,500 per month,
plus the RM25 per new member bonus (one bonus for both deals), plus modular pricing per
extra studio.

**To do before sending (~18 Nov):**
- [ ] Work samples (his brief asks for these first; our weakest part right now)
- [ ] Team names and the day-to-day contact
- [ ] Check every price against our real costs (15 pieces + 2 shoot days/month at RM7k?)
- [ ] Confirm with Kelvin that the member bonus is one bonus, not two
- [ ] Turn it into a PDF

---

## What's in this repo

| File | What it is |
|---|---|
| **[PROJECT-PLAN.md](PROJECT-PLAN.md)** | **Coach Hub delivery plan, phase by phase (confirmed 19 Nov)** |
| [HANDOVER.md](HANDOVER.md) | Original background (13 Nov): who Kelvin is, the first call, strategy, how we work |
| [BFT-Coach-Hub-Build-Plan-2026-09-27.pdf](BFT-Coach-Hub-Build-Plan-2026-09-27.pdf) | Kelvin's own Coach Hub plan |
| **prep/** | |
| [prep/call-briefing.md](prep/call-briefing.md) | Coach Hub explained in plain words: read this to understand the app |
| [prep/call-script.md](prep/call-script.md) | Script for the call with Kelvin, incl. the RM12k → RM5k pitch and pushback answers |
| [prep/audit-report-2026-11-14.md](prep/audit-report-2026-11-14.md) | Code review findings, written for Kelvin |
| [prep/pricing-options.md](prep/pricing-options.md) | The 4 pricing deals we considered and why we chose the partner deal |
| [prep/kelvin-message-draft.md](prep/kelvin-message-draft.md) | WhatsApp reply sent to Kelvin |
| [prep/stage3-pay-spec.md](prep/stage3-pay-spec.md) | Pay rules as tests + the 9 open questions |
| [prep/golden-month-oct-2026.md](prep/golden-month-oct-2026.md) | One coach's October invoice, worked out by hand (RM2,805.33, example rates) |
| [prep/invoice-mockup.html](prep/invoice-mockup.html) | Mock-up of the coach invoice and the Finance month-end screens |
| [prep/marketing/](prep/marketing/) | Kelvin's marketing brief + our proposal draft |
| **Engineering** | |
| [SESSION-LOG.md](SESSION-LOG.md) | Log of every work session (done / unverified / needs approval / open) |
| [REPOS.md](REPOS.md) | Map of Kelvin's code |
| [audit-kit/](audit-kit/) | Scripts that rebuild his database with fake data and re-run the security checks |
| [.claude/](.claude/) | Our AI crew setup: one AI builds, a separate one checks |
| [CONTRACT-TEMPLATE.md](CONTRACT-TEMPLATE.md) | Template for features that touch both the app and the database |

**Kelvin's app code is not in this repo.** It lives in his private repo
`bangsarmanagement/bft-coach-hub`. Ask Aaron for access.

## Ground rules

- Never push to Kelvin's `main` branch or run anything on his live database without his
  written OK. Every push to his `main` goes straight to his coaches.
- Never use real coach data for testing. Fake data only.
- Don't give tax or legal advice (LHDN e-invoicing, PERKESO, PDPA). His accountant and
  lawyer decide; we build what they say.

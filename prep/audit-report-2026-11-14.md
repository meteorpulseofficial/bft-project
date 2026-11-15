# BFT Coach Hub: code review

**For:** Kelvin · **Date:** 14 Nov 2026 · **Code reviewed:** `main` at commit `c1dae4e` (26 Sep 2026)

## In one paragraph

The app is in good shape. It builds cleanly, the database tests pass, every table has
row-level security turned on, and times are handled in KL time on purpose. That is a solid
base, and better than most AI-built apps we see. Before coaches are paid from it, we found
**7 things to harden**. They are mostly cases where a manager or a coach can do or see more
in the database than the screens allow. None of them shows up when you click through the
app, which is why they are easy to miss. Most are small database rule changes. We would fix
them, with a test for each, before Stage 3 (pay) is built on top.

## How we checked

We ran the app's own database on a private copy on our machine, filled with **made-up**
coaches and studios. We never touched your live site or your real data. We signed in as
each of the six roles and tried to read and change everything. Each finding below happened
twice, the same way both times.

## What is already solid

- Clean build: no type errors, no lint errors.
- No passwords or secret keys anywhere in the code or its history.
- Row-level security is on for all 20 tables. Coaches cannot read each other's PT, challenge
  payouts, reviews, absences or check-ins. Signed-out users see nothing.
- A manager at Bangsar cannot verify, assign, cancel or mark attendance at Subang.
- PT splits always add up exactly to the amount paid.
- Time rules hold at the edges: the 180-minute QR run (179 and 180 in, 181 out), the
  60-minute check-in window, the 24-hour drop line.
- Your SQL tests for Stages 1–2 all pass (see note 3 below on dates).

## Fix before coaches are paid (7)

| # | What we found | Why it matters |
|---|---|---|
| 1 | **A studio manager can open the private details of anyone in the company.** That includes the Owner, Finance, and coaches at other studios: phone, address and private notes. They can also change those notes. It works by quietly adding the person to their studio as an inactive member, then removing them again. | Personal data (PDPA). A manager could read or rewrite notes about themselves or others |
| 2 | **Every coach can read the studio's default Lead and Support rates**, and the PT and challenge %, straight from the database. No screen shows them, but the data is reachable. | Your plan says rates are Owner, GM and Finance only |
| 3 | **A coach can check in without being at the studio.** The QR code's secret can be read from the database by any coach. Anyone who has scanned once also keeps it. Only Owner/GM can change it, and when a manager tries, nothing happens. | Lateness and attendance feed pay. The QR scan is meant to prove the coach was there |
| 4 | **Verified classes are not locked.** After a manager verifies a class, attendance can still be changed (we turned "attended" into "no-show"). Attendance can also be set on cancelled classes and on classes in the future. A future "no-show" opens an absence, which can become a strike. | Your plan says "verified classes lock and flow into invoices". Once invoices exist, a change after verification would change pay |
| 5 | **A manager can put any coach into a Lead position directly.** That includes coaches without Lead status and coaches from another studio. The app's Assign button correctly refuses this; the database underneath does not. | Lead positions pay the Lead rate |
| 6 | **Challenge shares can add up to more than 100%.** We saved shares of 60 + 40 + 50 and paid out RM7,500 from a RM5,000 pool. Shares of 33.333% each also total RM500.01 from RM500.00. | This becomes coach pay as soon as Stage 3 reads it |
| 7 | **No staging copy, and no backups.** Every push to `main` goes straight to live coaches. Supabase is on the Free plan, which has no backups and pauses when idle. | One bad push, or one bad SQL file, and there is nothing to roll back to |

## Fix soon (6)

| # | What we found |
|---|---|
| 8 | A coach who answers an absence **after** the 5-day deadline still gets the strike removed. |
| 9 | The 5-day window and the 90-day strike window count from when the manager marks the no-show, not from the class date. A class from 100 days ago, marked today, still counts as a fresh strike. |
| 10 | If a manager corrects a no-show to "attended", the strike stays. |
| 11 | A full-time coach can drop a class their manager assigned to them. |
| 12 | A manager who is also a coach can approve their own PT, at 100%. An approved PT session can be edited later with no record of the change. |
| 13 | A manager can change a class's start time or headcount directly, and mark it verified. The app's checks and the coach notifications are skipped. |

## Small notes

- A few helper functions answer anyone, including people who are not signed in. One shows
  another coach's class clash ("Clashes with another class: BFT Subang Jaya 9:59am").
- Lateness rounds up: 10 minutes 1 second after call time counts as 11 minutes late. Is
  exactly 10:00 late? (Our question Q-4.)
- Your personal email and mobile number are written into a setup file in the repo. Fine
  while the repo is private. Remove them before anyone else sees the code.
- Your SQL tests use fixed dates in late September. Since about 1 October one of them
  (`50_claiming`) fails, and the tests after it stop running. They pass again with the dates
  moved forward, so the app is fine; the tests need a fixed clock.
- The README still says "Status: Stage 1".

## What we could not check without a staging copy

How the live Supabase API exposes these tables. The sign-in and invite emails. The storage
bucket for MC photos (file limits, who can open a photo). The live database time zone.
Scanning the QR on a real phone. The coach screens at phone size. All of these go on the
first staging run.

## What we suggest

1. **Staging first** (half a day): a second Supabase project with made-up data, and a
   Vercel preview branch. After that, nothing reaches coaches without passing there first.
   Supabase Pro for backups.
2. **Harden items 1–6 and 8–13** as numbered database changes, each with a test that fails
   before the fix and passes after. Your existing tests keep passing.
3. **Then Stage 3 (pay)**, built against a month of classes worked out by hand. Every pay
   change must reproduce that month to the sen before it ships.

Before Stage 3 starts, we also have 9 short questions on pay rules for you. For example:
does a special event's rate beat a coach's personal rate? And who gets the leftover sen when
a challenge pool splits three ways?

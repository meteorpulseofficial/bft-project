# One coach, one month, worked by hand: BFT Bangsar, October 2026

This is the **money golden file** (HANDOVER 11.2) in draft. It is one coach's invoice,
worked out by hand from the rules in Kelvin's plan. Once Kelvin confirms the numbers, every
pay change has to reproduce this total exactly, to the sen, before it ships.

> **Every rate here is an example.** The real default rates are set on the Studios page
> and are not in the PDF. Coach A and the PT clients are made up. No real coach data.
> Arithmetic checked by script, 13 Nov 2026.

## Setup

| Item | Value | Source |
|---|---|---|
| Studio | BFT Bangsar, billed to Studio 613 Sdn Bhd | PDF p.10 |
| Timetable | Mon–Fri 06:00, 07:10, 09:30, 12:30, 17:30, 18:40, 19:50 · Sat 07:00, 09:10, 10:30 · 55 min | PDF p.10 |
| Positions | 1 Lead + 1 Support per class | PDF p.10 |
| Default Lead rate | **RM60.00** per class | example |
| Default Support rate | **RM45.00** per class | example |
| Lead on a Support position | Support rate (studio default) | PDF p.4 |
| Coach A | Lead status at Bangsar, personal Lead rate **RM65.00**, no personal Support rate | example (Q-9) |
| Grace | 10 min after call time; call time = start − 30 min | PDF p.1, p.4 |
| Challenge % | 50% to coaches | PDF p.10 |
| PT split | 50/50 by default | PDF p.10 |

## Coach A's October

Claimed every Mon/Wed/Fri: **06:00 Lead** and **07:10 Support** (13 days: 2, 5, 7, 9, 12,
14, 16, 19, 21, 23, 26, 28, 30). Every Sat: **09:10 Lead** (3, 10, 17, 24, 31). Plus one
special event: **Sat 24 Oct, 11:30 Community Workout, Lead position, event rate RM80**.

The 06:00 + 07:10 pair is one QR run (07:10 starts 15 min after 06:00 ends), so one scan
covers both. On Sat 24 the 09:10 class ends 10:05 and the event starts 11:30, 85 min later,
so that is also one scan.

### What happened

| Date | Class | What happened | Rule | Pay effect |
|---|---|---|---|---|
| Fri 9 Oct | 06:00 Lead | Scanned 05:44. Call time 05:30, so 14 min late, past the 10 min grace | R-22 | Late item. Owner decides **deduction RM20** (example, Q-2) |
| Wed 14 Oct | 06:00 Lead | Scanned 05:38, 8 min after call time | R-20 | Not late. Full pay |
| Sat 17 Oct | 09:10 Lead | No-show. No explanation within 5 days | R-13 | RM0 + **1 strike** (not paused: 2 strikes needed) |
| Wed 21 Oct | 07:10 Support | Class cancelled by the studio | R-11 | RM0 |
| Sat 24 Oct | 11:30 event, Lead | Attended | R-06 | Coach rate RM65 beats event rate RM80 **as the PDF reads**. See Q-1 |
| Mon 26 Oct | 06:00 + 07:10 | Forgot to scan. Manager marked "Attended – no check-in", on time | R-16 | Full pay. Shows in late report as a forgotten scan |
| Sat 31 Oct | 09:10 Lead | Scanned 08:52. Call time 08:40, 12 min late | R-22 | Late item. Owner decides **full pay** |

### The invoice

**INVOICE: Coach A → Studio 613 Sdn Bhd · Cost centre: BFT Bangsar · October 2026**

| # | Line | Qty | Rate | Amount (RM) |
|---|---|---|---|---|
| 1 | Lead, Mon/Wed/Fri 06:00 | 13 | 65.00 | 845.00 |
| 2 | Lead, Sat 09:10 (5 claimed − 1 no-show) | 4 | 65.00 | 260.00 |
| 3 | Lead, special event 24 Oct (coach rate applies, Q-1) | 1 | 65.00 | 65.00 |
| 4 | Late deduction, Fri 9 Oct 06:00 (Owner decision) | 1 | −20.00 | −20.00 |
| 5 | Support, Mon/Wed/Fri 07:10 (13 claimed − 1 cancelled) | 12 | 45.00 | 540.00 |
| | **Classes subtotal** | | | **1,690.00** |
| 6 | 8 Week Challenge, Oct intake: revenue RM5,000.00 × 50% = pool RM2,500.00, split evenly 3 ways | 1 | | 833.33 |
| 7 | PT 6 Oct, Member P1, 60 min, paid RM150.00 × 50% | 1 | | 75.00 |
| 8 | PT 13 Oct, Member P2, 60 min, paid RM150.00 × 50% | 1 | | 75.00 |
| 9 | PT 20 Oct, Member P1, 90 min, paid RM220.00 × 60% (manager raised coach %) | 1 | | 132.00 |
| | **Extra earnings subtotal** | | | **1,115.33** |
| | **TOTAL** | | | **RM 2,805.33** |

Not on the invoice, and why:

- PT 27 Oct, Member P3, RM150.00: **still pending** at cut-off (R-52, Q-3).
- PT 29 Oct, Member P2, RM120.00: **rejected** (R-53).
- Sat 17 Oct no-show: RM0 (R-13). Wed 21 Oct cancelled: RM0 (R-11).

### What changes the total, if Kelvin answers differently

| Question | If the answer is… | Total becomes |
|---|---|---|
| Q-1: event rate wins over coach rate | line 3 = RM80.00 | RM 2,820.33 |
| Q-2: deduction is 50% of the line, not RM20 | line 4 = −32.50 | RM 2,792.83 |
| Q-5: leftover sen goes to the first coach listed, and that is Coach A | line 6 = 833.34 | RM 2,805.34 |
| Q-3: pending PT is paid if approved by the 3rd of next month | +RM75.00 | RM 2,880.33 |

### States this invoice passes through

1. **Draft:** 9 Oct and 31 Oct are late items, still undecided. **Cannot be approved** (R-26).
2. **Ready:** both late items decided. Sent to Owner and Finance.
3. **On hold**, if Coach A changes bank details now (R-33), until Finance approves.
4. **Approved → in bank file → Paid.**

## What this proves when it becomes a test

Each of these is a bug we would expect in a first version of pay code. The golden month
catches all of them in one run:

- the personal rate used on a Support position (line 5 would be RM65 × 12)
- the cancelled class or the no-show paid anyway
- the late item applied to both classes in the 06:00 + 07:10 run, not just the first
- the forgotten scan on 26 Oct treated as unpaid
- pending or rejected PT counted
- RM833.333… stored unrounded, or rounded differently on screen, in the PDF and in the bank file
- a class at 23:30 KL on 31 Oct dated 1 Nov in UTC (add one to the seed data)

# Call briefing: what Kelvin built (BFT Coach Hub)

For Aaron, so you can talk about it confidently. Sources: his build plan PDF (27 Sep) and
the GitHub repo (cloned 14 Nov).

## The problem it solves

BFT classes need coaches: 1 Lead + 1 Support per class by default. Kelvin uses
**part-time coaches**, so every week someone has to work out who takes which class, check
they turned up on time, and pay them correctly at month-end. Today that's done by hand
(WhatsApp, spreadsheets). Coach Hub moves it into one phone app.

**In one line:** "Uber-style shift claiming for fitness coaches, with QR check-in and
automatic monthly invoices."

## How it works, by person

**Part-time coach** (on their phone)
1. Opens the week's timetable and **claims** an open spot (Lead or Support).
2. Can **drop** it free until 24h before. Inside 24h they can only **swap** with another coach.
3. On the day: scans the **QR code** printed at the studio to check in. Call time is 30 min
   before class, with 10 min grace. One scan covers back-to-back classes within 3 hours.
4. If they miss a class (no-show), they have 5 days to explain, and can upload an MC. No
   good reason = no pay + 1 strike. 2 strikes in 90 days = can't book until a manager reviews.
5. Logs **PT sessions** they ran, and sees their earnings, review scores and (Stage 3) a
   monthly **invoice** to confirm.

**Studio manager** (one studio)
- Sets the weekly timetable and publishes classes. Adds coaches, promotes them to Lead.
- After each class, **verifies** who attended, who was late, who didn't show. Verified
  classes are what get paid.
- Approves PT sessions, enters 8 Week Challenge payouts, scores coaches (5 criteria, 1–10).

**Owner / GM** (all studios)
- Everything above, across studios. Adds new studios from Settings, with no code needed.
- Sets pay rates. Reviews late arrivals: full pay, deduction, or no pay.

**Finance**
- (Stage 3) Receives invoices, approves bank-detail changes, exports the bank transfer file,
  marks invoices paid.

## Where money comes from on a coach's invoice

1. **Classes** × rate. Rate order: the coach's personal rate → special event rate → the
   studio's default Lead/Support rate. A Lead covering a Support spot gets the Support rate.
2. **8 Week Challenge**: the studio enters challenge revenue. Coaches share 50% of it
   (default), split evenly or by custom %.
3. **PT**: coach logs a session and the amount the client paid. When the manager approves,
   it's split 50/50 by default.

One invoice per coach, per studio, per month, all billed to Studio 613 Sdn Bhd. That way
each studio is its own cost centre.

## Where he is

| Stage | What | Status |
|---|---|---|
| 1 Foundation | Logins, roles, studios, timetable, people | Live |
| Extras | Challenges, PT, coach reviews, GM role | Live |
| 2 Coach loop | Claim/drop/swap, QR check-in, verify, absences, strikes | Built, in testing |
| 3 Pay | Rates, late-pay review, invoices (PDF), bank details, bank file | **Not started**: the part he wants help with |
| 4 Pilot | 3–5 coaches for 2–3 weeks, WhatsApp reminders, Glofox sync | Not started |

He wants a team to **finish, test and deploy** it, not redesign it.

## The tech, in words you can say

- **Next.js on Vercel**: the app itself, a website that installs on the phone like an app.
- **Supabase**: the database plus logins (sign-in by a 6-digit email code). Hosted in
  Singapore, which matters for PDPA.
- **GitHub**: where the code lives. Every change pushed to `main` goes live straight away.
- **Row-level security**: rules inside the database that decide who sees which rows, so a
  coach only sees their own stuff even if they bypass the screens. He set this up on every
  table. That's good, and it's where most of our findings are (rules that are too loose).
- **Migrations**: numbered SQL files that build the database. He pastes them into Supabase
  by hand. There are 7 so far.
- He built it with Claude (the commits say so), over about 2 days (25–26 Sep). It's
  genuinely well organised for that.

## Things worth saying on the call

- "The rules in your plan are very clear: drop windows, the 180-minute QR run, strikes.
  That made it easy to test."
- "The foundation is right: multi-studio from day one, security on every table, KL time
  handled properly."
- "What's left is the risky part. Pay is where a mistake means a coach paid wrong. So we
  test every pay change against a month worked out by hand, to the sen."
- "Before pay, set up a staging copy and backups. Right now every push goes straight to
  your coaches, on the free plan with no backups."

## If he asks something you're unsure of

- **Glofox** = the BFT class booking system (ABC Fitness). His plan pulls the timetable
  from it once API access is approved. Until then, the weekly template works without it.
- **LHDN e-invoicing / PERKESO** = tax and social security for part-timers. His accountant
  decides; we build what they say.
- **PDPA** = Malaysia's data protection law. Coach data is stored in Singapore with consent.
  His lawyer approves the wording.
- **"What's the 180-minute rule?"** One QR scan covers a run of classes where each starts
  within 180 min of the previous one ending. So the 4 morning classes need one scan, and the
  evening classes need a second.

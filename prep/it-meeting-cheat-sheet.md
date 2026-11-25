# Your cheat sheet for the IT meeting (for Aaron)

Give the IT person **`BRIEFING-FOR-IT.md`** (the technical version). This page is for you: what to
say, what to ask, and what not to hand over yet.

---

## Before the meeting: one thing to check with Kelvin

The app, the code and the coaches' personal data belong to **Kelvin**. Before a new person sees
his code or data, send Kelvin a short message: you're bringing in an engineer to help, and ask if
he's OK with that person being added to GitHub/Supabase/Vercel. Until he says yes, show the IT
person the **briefing and the demo only** (fake data), not Kelvin's systems.

---

## How to explain it in 2 minutes (say it in your own words)

1. **The client:** Kelvin runs BFT gyms (Bangsar now, Subang next). He built an app called
   **Coach Hub** himself, using AI, to manage his part-time coaches.
2. **What the app does:** coaches book classes to teach, check in with a QR code, managers confirm
   attendance and handle no-shows, and soon it will work out each coach's monthly pay.
3. **What we were hired for:** check his app, fix the problems, finish it, and build the pay part.
   The agreed price is RM5,000 for the build *(share this only if you want to)*.
4. **What's done:** we checked the whole app and found 13 problems — for example, coaches could
   see each other's pay rates, and managers could change records after they were locked.
   **12 of the 13 are fixed and tested** on a practice copy with fake data. We also built a kit
   for a test copy of the app and backups.
5. **What isn't done:** nothing is live yet. Kelvin still has to approve and install the fixes.
   One fix (#12) isn't started. The pay part (the big one) hasn't started, and it needs Kelvin's
   answers to our questions first.
6. **What I need from you:** someone technical to own this from here, check what was built,
   talk to Kelvin's systems safely, and build the pay part.

---

## What to show (if you have 10 minutes)

- The **briefing** (`BRIEFING-FOR-IT.md`) — section 3's table is the status at a glance.
- The **audit report** (`prep/audit-report-2026-11-14.md`) — the 13 problems in plain words.
- The **demo app**, if it's running on your Mac (ask me to start it before the meeting).

---

## Questions to ask them (to see if they're the right person)

1. "Have you worked with **Next.js and Supabase** before? With Postgres row-level security?"
2. "How would you make sure a change never breaks the live app the coaches use?"
   *(Good answer mentions: a test copy/staging, branches and pull requests, testing first,
   backups, a way to undo.)*
3. "The fixes were built and checked with AI. How would you review them before they go live?"
4. "Have you handled **personal data** under PDPA? How do you keep passwords and keys safe?"
5. "How much time can you give per week, and how do you want to be paid — per hour, per phase?"
6. "Can you **explain things to me in plain words**, not tech talk?" *(Ask them to explain one
   thing from the briefing back to you. If you understand it, that's a good sign.)*
7. "What would you do in your first week?" *(Compare with section 6 of the briefing.)*

**Good signs:** asks about backups and testing before anything else; wants Kelvin's permission;
doesn't want to touch the live app straight away; explains clearly.
**Warning signs:** wants your passwords or "full access" on day one; says it's simple and can go
live quickly; dismisses testing; can't explain things simply.

---

## Don't hand over in the first meeting

- Any **passwords, login codes or keys** (yours, Kelvin's, the demo's).
- Access to **Kelvin's GitHub, Supabase or Vercel** — that comes from Kelvin, to their own account.
- Real coaches' details.

If you hire them, they should get **their own** accounts, added by Kelvin, with only the access
they need. Ask them to sign a simple **NDA / confidentiality** note (the code and data aren't yours
to share).

---

## Things you can decide together after the meeting

- Who talks to Kelvin about technical things from now on (you, them, or both).
- Whether they keep the current way of working (AI-assisted, with tests and reviews) or their own.
- Who opens the pull requests on Kelvin's GitHub (drafts are ready).
- Budget and timeline for the pay part (Stage 3).

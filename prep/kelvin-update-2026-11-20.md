# WhatsApp update for Kelvin (20 Nov 2026), Aaron to send

Send together with the "who should see what" questions (prep/access-questions-for-kelvin.md)
and the pay questions (Q-1 to Q-9 in prep/stage3-pay-spec.md), or right before them.

---

Hi Kelvin, quick update from our side. Nothing has been changed on your live app or your
coaches' data.

Done so far:
1. Fixed your database tests. One had been failing since early October because it was tied to
   the week of 28 Sep. They now work on any date, at any time of day.
2. Added a permanent safety check for who can see what in Coach Hub: 18 kinds of user, every
   table, 1,098 checks. If a future change leaks data (pay rates, bank details), it fails
   straight away.
3. Built a demo copy of Coach Hub with fake studios and coaches, so every fix gets tested
   there before it goes near your coaches.

Both changes are ready as pull requests, but we only have read access to the GitHub repo.
Could you give us write access? We only push to separate branches, and nothing reaches main
without your OK.

Three things from you when you can:
1. **Supabase Pro.** On the free plan your live database has no backups. This is the most
   important one.
2. **GitHub write access** (above), plus the Supabase and Vercel invites from my first message.
3. **Answers to a short list of questions** about who should see what, and about pay (sending
   next). Four of them are needed before we start the pay feature; the rest, no rush.

Next we're starting on the fixes from the review, beginning with private details and pay rates.

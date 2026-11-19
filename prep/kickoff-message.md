# Kick-off WhatsApp to Kelvin (after deposit), draft, Aaron to edit and send

---

Hi Kelvin, deposit received, thank you! 🙏 We're officially starting on Coach Hub.

A few things from your side to get us fully set up:

1️⃣ **Supabase → upgrade to Pro** (about US$25/month). This turns on daily backups, so if anything ever goes wrong we can restore. We won't put any fix live until this is on.

2️⃣ **Supabase → add me to your organisation** (Organization → Team → Invite): [your email]

3️⃣ **Vercel → add me to your team** (Settings → Members): [your email]
This lets us set up a test copy of the app with fake coaches, so nothing we try touches your real coaches.

4️⃣ **GitHub → protect the main branch** (repo Settings → Branches → add rule for `main` → "Require a pull request before merging"). Every change from us then waits for your approval before going live. Safer for both of us.

5️⃣ Two quick questions:
• Did you run the last two database files (6 and 7: claiming + check-in) in Supabase, or only up to 5?
• Have you changed anything since September that isn't on GitHub yet?

I'll also send you a short list of pay questions for Stage 3 (rates, pay date, which bank). No rush on those; we need them in about 2 weeks.

Meanwhile we're starting on the test setup and the fixes. I'll update you every few days 💪

---

## Notes for Aaron

- Replace **[your email]** with the email you want on his Supabase and Vercel.
- If he finds the GitHub step confusing, offer to do it on a short call, or skip it: our own
  rule is never to push to `main` anyway.
- The pay questions are in `prep/stage3-pay-spec.md` (bottom). Send them as a separate
  message in a few days, not all at once.

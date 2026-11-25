# Coach Hub demo copy (fake data)

Aaron's own copy of Kelvin's app for looking around and for showing fixes before they go
anywhere near the real app. **Everything in it is made up.** It never touches Kelvin's
Supabase, Vercel or coaches.

- Sign-in page: http://localhost:3001 (click a person; the app opens at http://localhost:3000)
- Database: Aaron's free Supabase project `coach-hub-demo` (ref `muczjyfeduajeupcbmfo`,
  Singapore), organisation "Coach Hub Demo". Created 20 Nov 2026.
- Code: since 25 Nov the demo runs **our fixed version** with every app fix through #12 (branch
  `crew/fix-12-app-pt`, worktree `.crew-wt/fix-12-app`) and the demo database has migrations
  0008–0021. Subang's PT split is 60% and Challenge 40% (changed 21 Nov so the two
  studios differ).
  Kelvin's untouched `main` is in `app/`. Both have a git-ignored `.env.local` starting with
  "DEMO COPY ONLY" pointing at the demo project.

## Starting it again (after a restart)

Ask Claude to "start the demo". Or run these two, each in its own terminal tab:

```bash
cd "/Users/aaron/Documents/BFT Project/.crew-wt/fix-12-app" && PATH=$HOME/.local/node/bin:$PATH npx next dev -p 3000
```

```bash
cd "/Users/aaron/Documents/BFT Project" && PATH=$HOME/.local/node/bin:$PATH node demo/signin-server.mjs
```

## Files

| File | What |
|---|---|
| `people.json` | The 13 fake people (all `@example.com`) and what each one shows |
| `create-users.mjs` | Creates their sign-in accounts (no emails sent) |
| `seed.sql` | Fake studios, timetable, 5 weeks of classes, attendance, no-shows, challenge, PT, review. Refuses to run if any non-demo person exists |
| `signin-server.mjs` | The "sign in as" page on port 3001 (this Mac only) |
| `psql-demo.sh` | Database console for the demo project only |
| `lib.mjs` | Shared; refuses to run unless `app/.env.local` points at the demo project |
| `.env.demo` | Demo database password, ref and host. Git-ignored, never share |

## Things to know

- Supabase pauses free projects after about a week with no use. If the app shows errors after
  a quiet week, restore the project at supabase.com → coach-hub-demo → Restore (free).
- The classes are dated around 20 Nov 2026 (two weeks back, three ahead). To refresh them
  later, rebuild: reset the project database, run the 7 migrations, `create-users.mjs`,
  then `seed.sql`.
- The demo shows Kelvin's app as it is today. Hafiz (set to inactive) is turned away by the
  screens; the known gap is underneath, in the database (see SESSION-LOG, inactive profile).

# Who should see what: questions for Kelvin (draft, Aaron to send with the pay questions)

Found by the crew while building the permanent access test (20 Nov 2026). Kelvin's plan
does not settle these. Until he answers, the test records how the app behaves **today** and
marks each one "pending Kelvin", so nothing is blocked. Each answer becomes a fixed rule.

Questions 1, 2, 3 and 12 matter most: they decide who sees pay rates and bank details in
Stage 3, and whether a person who has left can still see them.

Numbering here is for Kelvin. The test file's tags map as: here 1→Q1, 2→Q2, 3→Q10,
4→Q3, 5→Q4 (all of Finance's view of people, incl. strikes_cleared_at), 6→Q6, 7→Q5,
8→open:mgr-reads-admin-as-coach + open:mgr-reads-comanager, 8b→open:coach-reads-manager-note, 9→Q7, 10→Q8, 11→Q9,
12→open:inactive-profile, 13→open:manager-token, 14→Q11, 15→Q12, 16→Q13.
17→ app rule in src/lib/people-policy.ts (canAddExistingPerson).
18→ contracts/fix-2-rates/CONTRACT.md D5 (studio_default_splits).
19→ contracts/fix-3-checkin/CONTRACT.md (photographable QR; D4 Finance).
20→ contracts/fix-4-verified-lock/CONTRACT.md D2 (Owner/GM correction).
21→ contracts/fix-5-lead-positions/CONTRACT.md D13/D14.
Not asked (internal): open:cover-rule (we treat the cover rate as a rate).

---

Hi Kelvin, while setting up the safety checks we listed exactly who can see what in Coach
Hub today. A few things your plan doesn't say, so we'd like your call:

**Pay and bank details**
1. Bank details: your plan says Owner, GM and Finance can see them. Should the **GM** see
   coaches' bank details, or only you and Finance?
2. Pay rates: should **Finance** see the coaches' rates and studio settings (including the
   QR check-in code)? Today they can.
3. 8 Week Challenge: coaches in a challenge can see its **total revenue** and the coaches'
   **% of revenue** today. OK, or should they only see their own payout?

**Coaches' personal details**
4. Every staff member can see **everyone's name** across both studios (not phone or address).
   OK?
5. Finance can see **everyone's phone, address and attendance**. Intended?
6. A coach who works at **both studios**: both studio managers see and edit the same
   private notes about them. OK, or should each studio keep its own notes?
7. Can a studio manager, the GM or you read the **private notes written about yourselves**?
   (Coaches can't read theirs.)
8. If you, the GM or Finance also **coach at a studio**, that studio's manager can read
   your phone, address and private notes like any other coach's. OK? And if a studio has
   **two managers**, they can read each other's private notes. OK?
8b. When a coach explains an absence, they can read the **manager's note** on it. OK, or
    should that note be for managers only?

**Coaches seeing each other**
9. Coaches can see which other coaches are **Lead**-approved and when strikes were cleared.
   OK?
10. Your plan says the **reliability score is visible to everyone**, but absences are only
    visible to the coach and their manager. Who should see the score?
11. **Full-time coaches**: should they see the whole studio timetable, or only the classes
    assigned to them?

**When someone leaves**
12. If you switch a person to **inactive**, the app's screens turn them away, but the
    database behind it still gives them their studio's timetable, the pay rates and the QR
    check-in code if they ask it directly (their sign-in stays valid). We suggest the
    database also gives inactive people nothing. Agree?
13. Studio managers can see the **QR check-in code** (the app has a screen to show it at
    the studio). Should anyone else be able to?

**Smaller ones**
14. Company details (registration number, address) are visible to every signed-in user. OK?
15. The setup table with your email and phone is hidden from everyone, including you. OK?
16. Someone who isn't signed in sees nothing at all. Confirm that's what you want.

**Adding coaches (from our first fix)**
17. A studio manager can no longer add someone who **already has a Coach Hub account
    elsewhere** (e.g. a Bangsar coach being added to Subang). Today that let any manager read
    and change that person's phone, address and notes. For now you or the GM add shared
    coaches to a second studio. Happy with that, or should managers be able to do it?

**Pay rates (from our second fix)**
18. Coaches can no longer see the studio's pay rates. Studio managers can't see the Lead and
    Support rates either, only their own studio's **default PT and Challenge split %**, because
    their PT-approval and Challenge screens use it. OK, or should managers not see those
    either? Also: a coach can still look up **their own studio's default PT %** (the same number
    shown on their own PT sessions), even if they don't do PT. OK?

No rush. We need 1, 2, 3 and 12 before Stage 3 (pay) starts.

**QR check-in (from our third fix)**
19. Only the studio manager and you/the GM can now see the QR code, and a manager can make a
    new code (the old one stops working at once). But a printed code can still be photographed
    and shared. Would you like a code that changes by itself (shown on a tablet at the studio),
    or a location check when scanning? Or is "make a new code if it's shared" enough for now?
    Finance no longer sees the code either (part of question 2).

**Verified classes (from our fourth fix)**
20. Once a class is verified, a studio manager can no longer change its attendance or coaches.
    You and the GM still can, to fix mistakes. Is that right, or should nobody be able to change
    a verified class (or only before that month's invoices go out)?

**Lead status and Lead pay (from our fifth fix)**
21. Nobody can put a coach without Lead status into a Lead spot any more. But a studio manager
    can still give a coach Lead status, put them in a Lead spot, then take the status away, and
    the coach keeps the Lead spot (and Lead pay). Should only you and the GM be able to give Lead
    status? Or should pay use the Lead status the coach had on the day of the class? Related:
    you/the GM can't correct an old class for a coach who has since lost Lead status or left.

**Staging and backups (from our seventh fix)**
22. Is the GitHub repo private? The nightly backup stores an encrypted copy of the database as a
    GitHub "artifact", which anyone with read access to the repo can download.
23. Did you connect Supabase's GitHub integration, or ever use `supabase db push`? If so there is a
    second record of database changes, and we need to know before switching to our script.
24. Have any of our database changes (0008 onwards) already been pasted into the live database?
25. Uploaded files (for example absence evidence photos) are not in any database backup, including
    Supabase Pro's daily one. Are files being uploaded today, and how should we back them up?
26. Money and accounts (your decision): Supabase Pro for the live project (about US$25 a month:
    daily backups kept 7 days, and it stops pausing), a second free Supabase project for staging,
    and invites for us to Supabase, Vercel and GitHub with the least access needed.

**Absences and strikes (from our eighth fix)**
27. A coach can no longer send an absence explanation after the deadline; a missed deadline is a
    strike unless the manager excuses it. We also made two safe defaults you may want to loosen:
    a studio manager can't decide their **own** absence (you or the GM decide it), and a manager
    can't change an absence decision once made (you or the GM can). Are these right? And should a
    manager be able to excuse a missed deadline at all?
28. The 5 days to explain start when the class is marked (verified), not from the class itself,
    and the deadline is the exact time (now shown with the time, e.g. "Sun 1 Dec, 6:15pm"). Should
    it instead be end of day, or count from the class date? (This is also our audit item #9.)
29. Any signed-in coach can look up another coach's strike count (not the absences themselves).
    Should strike counts be private to the coach and their managers?
30. Should a manager be able to mark a no-show for a class older than the strike window, or in a
    month whose invoices are already done? Today they can (it can't be a strike any more, but the
    class becomes unpaid).
31. "Resume booking" forgives every absence recorded up to that moment, including ones still
    waiting for an answer. Should it only forgive strikes that already existed then?

**Correcting a no-show (from our tenth fix)**
32. When a no-show is corrected to "attended" or "late", the absence is removed and kept in a
    record only you and the GM can see. If the coach uploaded a medical certificate, the photo
    stays in storage: the coach can delete it, managers can still open it. Should it be deleted
    automatically (personal data), kept, or kept for a set time?
33. We made two safe defaults you may want to change: nobody can mark their **own** attendance
    except you and the GM (so a manager who also coaches needs another manager), and only you or
    the GM can correct a no-show that has already been decided. Are these right?
34. Should Finance also see the record of corrected no-shows?
35. Existing data: when our change runs, it counts no-shows already corrected to "attended" whose
    strike stayed (the bug). We leave them as they are. Should we remove those strikes too, after
    you check the list?

**Class edits (from our thirteenth fix)**
36. Classes and coach slots can now only be changed through the app's own buttons (create
    timetable, assign, cancel, change type, verify), not directly, not even by you or the GM. Once a
    coach's attendance or no-show is recorded, that slot's coach can't be changed. **How should a
    manager record a walk-in substitute after a class has started?** (Today the only way was the
    loophole we closed.) We can build a "record substitute" or "Owner correction" button if you
    want one.
37. Should managers be able to move a class's time? If yes, should coaches be notified, and must
    they confirm?
38. Who may mark a class as a special event (it pays a different rate)?
39. Is deleting a class ever needed, or only cancelling? (A class or studio with a no-show on
    record can no longer be deleted.)
40. If a class is cancelled after a coach was marked a no-show, should the strike stay?

**Full-time schedules (from our eleventh fix)**
41. Full-time coaches can no longer drop or swap their classes; the manager reassigns them. **If a
    manager puts a part-time coach on a class, may that coach still drop it freely (up to 24 hours
    before), or only by asking the manager?** The app now hides Drop on those classes, but the
    database still allows it until you decide.
42. Should full-time coaches be allowed to swap with each other if the manager approves?
43. Is anyone full-time at one studio and part-time at another? The app stores one type per person,
    so today they'd be treated as full-time everywhere.
44. When a part-timer drops a class, should the studio manager get a notice that it's open again?
    (Today nobody is told.)

**PT approvals (from our twelfth fix)**
45. A studio manager can no longer approve their own PT; another manager, you or the GM must. You and
    the GM can still approve your own (it's recorded). **Should the GM's own PT need your approval,
    and yours the GM's?**
46. Approved PT is now locked. Only you or the GM can correct the amount, split or status, and nobody
    can move it to another date or delete it. Who should be allowed to reverse an approval, and until
    when (for example, until that month's pay is done)?
47. You or the GM can set an approved session back to "pending", after which the coach can edit it
    again. Should that be allowed?
48. Every change to a PT session is now kept in a history only you and the GM can see (it holds client
    names and amounts). Should Finance or the studio manager see it too?
49. Who can run PT sessions: can Finance staff, or you, log PT? (Today: only active coaches and
    managers of that studio, plus you and the GM.)
50. If a coach leaves before their pending PT is approved, should it still be paid? (We allow approving
    it.)
51. May PT be logged for a past month after its pay is done? Is there a limit on how far back?
52. Is there a maximum split a studio manager may set for a coach, or may only you/the GM go above the
    studio default?

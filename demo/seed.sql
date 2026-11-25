-- DEMO DATA ONLY. Fake studios, people and classes for Aaron's demo copy of Coach Hub.
-- Never run on Kelvin's database. Run after the 7 migrations and after create-users.mjs
-- has created the 13 sign-in accounts (all @example.com).
\set ON_ERROR_STOP 1
begin;

do $$
begin
  if exists (select 1 from public.profiles p join public.profile_contacts c on c.profile_id = p.id
             where c.email not like '%@example.com') then
    raise exception 'Refusing: this database has non-demo people in it';
  end if;
  if (select count(*) from auth.users where email like '%@example.com') < 13 then
    raise exception 'Create the 13 demo accounts first (create-users.mjs)';
  end if;
  if exists (select 1 from public.classes) then
    raise exception 'Already seeded';
  end if;
end $$;

-- People lookup by key
create temp table ppl as
select split_part(u.email, '@', 1) as k, u.id
from auth.users u where u.email like '%@example.com';
create temp table k2 (key text, local text);
insert into k2 values ('owner','owner'),('gm','gm'),('finance','finance'),('mgr-bgs','meiling'),
  ('mgr-sbj','suresh'),('aisha','aisha'),('ben','ben'),('chloe','chloe'),('daniel','daniel'),
  ('emma','emma'),('faiz','faiz'),('grace','grace'),('hafiz','hafiz');
create temp table p as select k2.key, ppl.id from k2 join ppl on ppl.k = k2.local;

create function pg_temp.pid(text) returns uuid language sql stable as $f$ select id from p where key = $1 $f$;

-- Kelvin's real details from migration 2 are replaced with demo ones
delete from public.bootstrap_owners;
insert into public.bootstrap_owners (email, full_name, phone) values ('owner@example.com', 'Olivia Tan', '+60120000001');
update public.companies set name = 'Demo Fitness Sdn. Bhd.', reg_no = '000000000000',
  address = '1 Jalan Contoh, 50000 Kuala Lumpur';

-- Act as the owner for functions that check who is calling
select set_config('request.jwt.claim.sub', pg_temp.pid('owner')::text, true),
       set_config('request.jwt.claims', json_build_object('sub', pg_temp.pid('owner'), 'role', 'authenticated')::text, true);

-- Organisation roles and active flags
update public.profiles set org_role = 'owner' where id = pg_temp.pid('owner');
update public.profiles set org_role = 'gm' where id = pg_temp.pid('gm');
update public.profiles set org_role = 'finance' where id = pg_temp.pid('finance');
update public.profiles set active = false where id = pg_temp.pid('hafiz');
update public.profile_contacts c set address = v.addr
from (values ('aisha','12 Jalan Maarof, Bangsar'), ('ben','8 Lorong Kurau, Bangsar'),
             ('chloe','3 Jalan SS15/4, Subang Jaya'), ('daniel','21 Jalan Telawi 5, Bangsar'),
             ('emma','9 Jalan SS17/1, Subang Jaya'), ('faiz','45 Jalan USJ 2, Subang Jaya'),
             ('grace','17 Jalan Bangsar, KL'), ('hafiz','2 Jalan Ara, Bangsar')) v(key, addr)
where c.profile_id = pg_temp.pid(v.key);

-- Studio rules and pay
update public.studios set lead_rate = 80, support_rate = 60 where code = 'BGS';
update public.studios set lead_rate = 75, support_rate = 55 where code = 'SBJ';

-- Subang timetable (migration 2 only has Bangsar's): Mon–Fri 06:30, 18:00, 19:10; Sat 08:00, 09:15
insert into public.template_slots (studio_id, weekday, start_time, duration_min, class_type_id)
select st.id, d.w, t.s::time, 55, ct.id
from public.studios st join public.class_types ct on ct.studio_id = st.id and ct.name = 'BFT Session'
cross join (values (1),(2),(3),(4),(5)) d(w) cross join (values ('06:30'),('18:00'),('19:10')) t(s)
where st.code = 'SBJ'
union all
select st.id, 6, t.s::time, 55, ct.id
from public.studios st join public.class_types ct on ct.studio_id = st.id and ct.name = 'BFT Session'
cross join (values ('08:00'),('09:15')) t(s)
where st.code = 'SBJ';

-- Studio memberships
insert into public.studio_members (studio_id, profile_id, role, is_lead, active)
select s.id, pg_temp.pid(m.key), m.role::public.studio_role, m.lead, m.active
from (values
  ('BGS','mgr-bgs','manager',false,true),
  ('SBJ','mgr-sbj','manager',false,true),
  ('BGS','aisha','coach',true,true),
  ('BGS','ben','coach',false,true),
  ('BGS','chloe','coach',true,true),
  ('SBJ','chloe','coach',false,true),
  ('BGS','daniel','coach',true,true),
  ('SBJ','emma','coach',true,true),
  ('SBJ','faiz','coach',false,true),
  ('BGS','grace','coach',false,true),
  ('BGS','hafiz','coach',false,false)
) m(code, key, role, lead, active)
join public.studios s on s.code = m.code;

-- Classes: two weeks back to three weeks ahead (KL dates)
select public.generate_classes(s.id, (now() at time zone 'Asia/Kuala_Lumpur')::date - 14,
                               (now() at time zone 'Asia/Kuala_Lumpur')::date + 21)
from public.studios s;

-- Fill positions. Leads only from Lead-approved coaches. Past classes are fully staffed;
-- future ones about half, so there are open spots to claim.
create temp table cls as
select c.id, c.studio_id, s.code, c.starts_at,
       row_number() over (partition by c.studio_id order by c.starts_at) as n,
       c.starts_at < now() as past
from public.classes c join public.studios s on s.id = c.studio_id;

create function pg_temp.pick(p_list text[], p_n bigint) returns uuid language sql stable as $f$
  select pg_temp.pid(p_list[1 + (p_n % array_length(p_list, 1))::int])
$f$;

-- Bangsar lead: Daniel (full-time) does the 06:00 and 07:10, others rotate
update public.positions po set coach_id = case
    when extract(hour from c.starts_at at time zone 'Asia/Kuala_Lumpur') in (6, 7) then pg_temp.pid('daniel')
    else pg_temp.pick(array['aisha','chloe'], c.n) end,
  assigned_by = pg_temp.pid('mgr-bgs'), claimed_at = c.starts_at - interval '6 days'
from cls c
where po.class_id = c.id and c.code = 'BGS' and po.role = 'lead'
  and (c.past or c.n % 2 = 0 or extract(hour from c.starts_at at time zone 'Asia/Kuala_Lumpur') in (6, 7));

update public.positions po set coach_id = pg_temp.pick(array['ben','aisha','chloe','ben'], c.n + 1),
  claimed_at = c.starts_at - interval '5 days'
from cls c
where po.class_id = c.id and c.code = 'BGS' and po.role = 'support'
  and (c.past or c.n % 3 = 0)
  and not exists (select 1 from public.positions o where o.class_id = c.id and o.coach_id = pg_temp.pick(array['ben','aisha','chloe','ben'], c.n + 1));

update public.positions po set coach_id = pg_temp.pick(array['emma'], c.n),
  claimed_at = c.starts_at - interval '6 days'
from cls c
where po.class_id = c.id and c.code = 'SBJ' and po.role = 'lead' and (c.past or c.n % 2 = 1);

update public.positions po set coach_id = pg_temp.pick(array['faiz','chloe','faiz'], c.n),
  claimed_at = c.starts_at - interval '5 days'
from cls c
where po.class_id = c.id and c.code = 'SBJ' and po.role = 'support' and (c.past or c.n % 3 = 1);

-- One cancelled class next week (Bangsar)
update public.classes set status = 'cancelled', cancelled_at = now(), cancelled_by = pg_temp.pid('mgr-bgs'),
  cancel_reason = 'Aircon repair'
where id = (select id from cls where code = 'BGS' and starts_at > now() + interval '5 days' order by starts_at limit 1);
update public.positions set coach_id = null, claimed_at = null, assigned_by = null
where class_id = (select id from public.classes where status = 'cancelled');

-- Attendance for past classes: mostly on time, some late, two no-shows
insert into public.attendance (position_id, profile_id, checkin_at, minutes_late, status, verified_by, verified_at)
select po.id, po.coach_id,
       case when (c.n + po.seq) % 11 = 0 then c.starts_at + interval '7 minutes'
            else c.starts_at - interval '35 minutes' end,
       case when (c.n + po.seq) % 11 = 0 then 7 else 0 end,
       case when (c.n + po.seq) % 11 = 0 then 'late' else 'attended' end,
       case when c.starts_at < now() - interval '2 days' then pg_temp.pid(case c.code when 'BGS' then 'mgr-bgs' else 'mgr-sbj' end) end,
       case when c.starts_at < now() - interval '2 days' then c.starts_at + interval '2 hours' end
from public.positions po join cls c on c.id = po.class_id
where c.past and po.coach_id is not null;

insert into public.check_ins (studio_id, profile_id, scanned_at)
select c.studio_id, a.profile_id, a.checkin_at
from public.attendance a join public.positions po on po.id = a.position_id join cls c on c.id = po.class_id
where a.checkin_at is not null;

update public.classes cl set headcount = 14 + (c.n % 9)::int, verified_at = c.starts_at + interval '2 hours',
  verified_by = pg_temp.pid(case c.code when 'BGS' then 'mgr-bgs' else 'mgr-sbj' end)
from cls c where cl.id = c.id and c.starts_at < now() - interval '2 days';

-- No-show 1: Ben, a week ago, still to explain
with x as (
  select a.position_id, po.class_id from public.attendance a join public.positions po on po.id = a.position_id
  join cls c on c.id = po.class_id
  where a.profile_id = pg_temp.pid('ben') and c.starts_at between now() - interval '4 days' and now() - interval '1 day'
  order by c.starts_at limit 1)
update public.attendance a set status = 'no_show', checkin_at = null, minutes_late = 0
from x where a.position_id = x.position_id;
delete from public.check_ins ci using public.attendance a
where a.status = 'no_show' and ci.profile_id = a.profile_id
  and ci.scanned_at = (select c.starts_at - interval '35 minutes' from public.positions po join cls c on c.id = po.class_id where po.id = a.position_id);
insert into public.absences (position_id, profile_id, studio_id, due_at)
select a.position_id, a.profile_id, c.studio_id, now() + interval '3 days'
from public.attendance a join public.positions po on po.id = a.position_id join cls c on c.id = po.class_id
where a.status = 'no_show' and a.profile_id = pg_temp.pid('ben');

-- No-show 2: Faiz, explained, waiting for the manager
with x as (
  select a.position_id from public.attendance a join public.positions po on po.id = a.position_id
  join cls c on c.id = po.class_id
  where a.profile_id = pg_temp.pid('faiz') and c.starts_at between now() - interval '6 days' and now() - interval '2 days'
  order by c.starts_at limit 1)
update public.attendance a set status = 'no_show', checkin_at = null, minutes_late = 0
from x where a.position_id = x.position_id;
insert into public.absences (position_id, profile_id, studio_id, due_at, reason, explanation, submitted_at)
select a.position_id, a.profile_id, c.studio_id, now() + interval '1 day', 'medical',
       'Had a fever that morning, messaged Suresh at 5am.', now() - interval '1 day'
from public.attendance a join public.positions po on po.id = a.position_id join cls c on c.id = po.class_id
where a.status = 'no_show' and a.profile_id = pg_temp.pid('faiz');

-- 8 Week Challenge (Bangsar), paid this month
with ch as (
  insert into public.challenges (studio_id, name, start_date, pay_month, revenue, coach_pct, created_by)
  select id, '8 Week Challenge (Sep intake)', date_trunc('month', now() at time zone 'Asia/Kuala_Lumpur')::date - 56,
         date_trunc('month', now() at time zone 'Asia/Kuala_Lumpur')::date, 12000, 50, pg_temp.pid('mgr-bgs')
  from public.studios where code = 'BGS' returning id)
insert into public.challenge_coaches (challenge_id, profile_id, team_size, share_pct)
select ch.id, pg_temp.pid(v.k), v.t, v.s from ch, (values ('aisha', 12, 60.0), ('chloe', 8, 40.0)) v(k, t, s);

-- PT sessions
insert into public.pt_sessions (studio_id, coach_id, client_name, session_date, amount_paid, coach_pct, status)
select s.id, pg_temp.pid(v.k), v.client, (now() at time zone 'Asia/Kuala_Lumpur')::date - v.ago, v.amt, 50, v.st::public.approval_status
from (values ('BGS','aisha','Client A (demo)', 9, 150, 'approved'),
             ('BGS','aisha','Client B (demo)', 4, 150, 'approved'),
             ('BGS','aisha','Client A (demo)', 1, 150, 'pending'),
             ('SBJ','emma','Client C (demo)', 6, 120, 'approved')) v(code, k, client, ago, amt, st)
join public.studios s on s.code = v.code;

-- A coach review
insert into public.coach_reviews (profile_id, studio_id, reviewer_id, review_date, care_and_concern, technique, english, ice_breaking, talk_time, comments)
select pg_temp.pid('ben'), s.id, pg_temp.pid('mgr-bgs'), (now() at time zone 'Asia/Kuala_Lumpur')::date - 10, 8, 7, 9, 6, 7,
       'Good energy. Work on talking to members before class starts.'
from public.studios s where s.code = 'BGS';

-- Private manager note
insert into public.profile_notes (profile_id, notes, updated_by)
values (pg_temp.pid('ben'), 'Prefers evening classes. Studying part-time until March.', pg_temp.pid('mgr-bgs'));

-- Notifications
insert into public.notifications (profile_id, title, body, link)
values (pg_temp.pid('ben'), 'Missed class: please explain', 'You were marked as a no-show. Explain within 5 days.', '/absences'),
       (pg_temp.pid('mgr-sbj'), 'Absence to review', 'Faiz Hassan explained a missed class.', null),
       (pg_temp.pid('aisha'), 'PT session approved', 'Client B (demo) was approved.', '/pt');

commit;

select 'Demo data loaded' as result,
       (select count(*) from public.classes) as classes,
       (select count(*) from public.positions where coach_id is not null) as filled_positions,
       (select count(*) from public.positions where coach_id is null) as open_positions;

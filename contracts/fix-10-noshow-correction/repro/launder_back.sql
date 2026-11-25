\set ON_ERROR_STOP 1
\set VERBOSITY terse
begin;
set local client_min_messages = warning;
insert into auth.users (id, email) values ('11111111-0000-0000-0000-000000000001','mc@x.test'),('11111111-0000-0000-0000-000000000002','co@x.test'),('11111111-0000-0000-0000-000000000003','m2@x.test');
insert into public.companies (id, name) values ('22222222-0000-0000-0000-000000000001','Co');
insert into public.studios (id, company_id, name, code, checkin_token, timezone, noshow_explain_days, strike_limit, strike_window_days, late_grace_min)
 values ('33333333-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000001','S','RVS','rvtok000000000000000001','Asia/Kuala_Lumpur',5,2,90,10);
insert into public.studio_members (studio_id, profile_id, role, is_lead, active) values
 ('33333333-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000001','manager',false,true),
 ('33333333-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000001','coach',false,true),
 ('33333333-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000002','coach',false,true),
 ('33333333-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000003','manager',false,true);
insert into public.class_types (id, studio_id, name) values ('66666666-0000-0000-0000-000000000001','33333333-0000-0000-0000-000000000001','Ride');
insert into public.classes (id, studio_id, class_type_id, starts_at, duration_min, status) values ('44444444-0000-0000-0000-000000000001','33333333-0000-0000-0000-000000000001','66666666-0000-0000-0000-000000000001', now() - interval '2 hours', 55, 'scheduled');
insert into public.positions (id, class_id, role, seq, coach_id) values ('55555555-0000-0000-0000-000000000001','44444444-0000-0000-0000-000000000001','support',1,'11111111-0000-0000-0000-000000000001');
-- 1. m2 marks mc no_show (undecided absence, mc's)
select set_config('request.jwt.claim.sub','11111111-0000-0000-0000-000000000003',true) \g /dev/null
set local role authenticated;
select public.set_attendance('55555555-0000-0000-0000-000000000001','no_show',0,false) \g /dev/null
reset role;
select 'step1 absence owner is mc' as s, count(*) from public.absences where profile_id='11111111-0000-0000-0000-000000000001';
-- 2r. mc: move class to the future, hand P to CO and back to MC (attendance cleared), move class to 5 min ago, scan
select set_config('request.jwt.claim.sub','11111111-0000-0000-0000-000000000001',true) \g /dev/null
set local role authenticated;
update public.classes set starts_at = now() + interval '1 day' where id='44444444-0000-0000-0000-000000000001';
select public.assign_position('55555555-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000002') \g /dev/null
select public.assign_position('55555555-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000001') \g /dev/null
update public.classes set starts_at = now() - interval '5 minutes' where id='44444444-0000-0000-0000-000000000001';
select 'mc check_in' as s, public.check_in('rvtok000000000000000001');
reset role;
select 'step2r coach=mc / att / mc absences' as s, (select coach_id = '11111111-0000-0000-0000-000000000001' from public.positions where id='55555555-0000-0000-0000-000000000001'),
  (select status||'/'||(checkin_at is not null) from public.attendance where position_id='55555555-0000-0000-0000-000000000001'),
  (select count(*) from public.absences where profile_id='11111111-0000-0000-0000-000000000001');
-- 3r. m2 runs routine verify_class
select set_config('request.jwt.claim.sub','11111111-0000-0000-0000-000000000003',true) \g /dev/null
set local role authenticated;
\set ON_ERROR_STOP 0
select 'm2 verify_class' as s, public.verify_class('44444444-0000-0000-0000-000000000001', 12);
\set ON_ERROR_STOP 1
reset role;
select 'step3r mc absences left / att / verified / notice' as s,
  (select count(*) from public.absences where profile_id='11111111-0000-0000-0000-000000000001'),
  (select status from public.attendance where position_id='55555555-0000-0000-0000-000000000001'),
  (select verified_at is not null from public.classes where id='44444444-0000-0000-0000-000000000001'),
  (select body from public.notifications where profile_id='11111111-0000-0000-0000-000000000001' and title='Attendance corrected');
rollback;

\set ON_ERROR_STOP 1
insert into auth.users (id,email) values
('00000000-0000-0000-0000-0000000000a0','kcl211@gmail.com'),
('00000000-0000-0000-0000-0000000000a1','gm@x'),
('00000000-0000-0000-0000-0000000000a2','fin@x'),
('00000000-0000-0000-0000-0000000000b1','mgr_bgs@x'),
('00000000-0000-0000-0000-0000000000b2','mgr_sbj@x'),
('00000000-0000-0000-0000-0000000000c1','pt1@x'),
('00000000-0000-0000-0000-0000000000c2','pt2@x'),
('00000000-0000-0000-0000-0000000000c3','ft@x'),
('00000000-0000-0000-0000-0000000000d1','sbj@x');
update profiles set full_name = split_part((select email from auth.users u where u.id=profiles.id),'@',1);
update profiles set org_role='gm' where id='00000000-0000-0000-0000-0000000000a1';
update profiles set org_role='finance' where id='00000000-0000-0000-0000-0000000000a2';
update profiles set employment_type='full_time' where id='00000000-0000-0000-0000-0000000000c3';
update studios set lead_rate=80, support_rate=50;
update profile_contacts set phone='+60'||right(profile_id::text,2), address='addr '||right(profile_id::text,2);
insert into studio_members (studio_id,profile_id,role,is_lead)
select s.id, x.p::uuid, x.r::studio_role, x.l from studios s join (values
 ('BGS','00000000-0000-0000-0000-0000000000b1','manager',false),
 ('SBJ','00000000-0000-0000-0000-0000000000b2','manager',false),
 ('BGS','00000000-0000-0000-0000-0000000000c1','coach',true),
 ('BGS','00000000-0000-0000-0000-0000000000c2','coach',false),
 ('BGS','00000000-0000-0000-0000-0000000000c3','coach',false),
 ('SBJ','00000000-0000-0000-0000-0000000000d1','coach',true),
 ('SBJ','00000000-0000-0000-0000-0000000000c2','coach',false)
) x(code,p,r,l) on s.code=x.code;
insert into profile_notes (profile_id, notes) select id, 'secret note on '||full_name from profiles;
-- classes: past (yesterday) and future (+5 days) in each studio
insert into classes (id, studio_id, class_type_id, starts_at, duration_min)
select x.id::uuid, s.id, (select id from class_types where studio_id=s.id limit 1), x.t::timestamptz, 55
from studios s join (values
 ('BGS','11111111-0000-0000-0000-000000000001', now()-interval '1 day'),
 ('BGS','11111111-0000-0000-0000-000000000002', now()+interval '5 days'),
 ('SBJ','22222222-0000-0000-0000-000000000001', now()-interval '1 day'),
 ('SBJ','22222222-0000-0000-0000-000000000002', now()+interval '5 days')
) x(code,id,t) on s.code=x.code;
insert into positions (id,class_id,role,seq,coach_id) values
('11111111-0000-0000-0000-0000000000a1','11111111-0000-0000-0000-000000000001','lead',1,'00000000-0000-0000-0000-0000000000c1'),
('11111111-0000-0000-0000-0000000000a2','11111111-0000-0000-0000-000000000001','support',1,'00000000-0000-0000-0000-0000000000c2'),
('11111111-0000-0000-0000-0000000000b1','11111111-0000-0000-0000-000000000002','lead',1,null),
('11111111-0000-0000-0000-0000000000b2','11111111-0000-0000-0000-000000000002','support',1,null),
('22222222-0000-0000-0000-0000000000a1','22222222-0000-0000-0000-000000000001','lead',1,'00000000-0000-0000-0000-0000000000d1'),
('22222222-0000-0000-0000-0000000000a2','22222222-0000-0000-0000-000000000001','support',1,'00000000-0000-0000-0000-0000000000c2'),
('22222222-0000-0000-0000-0000000000b1','22222222-0000-0000-0000-000000000002','lead',1,null),
('22222222-0000-0000-0000-0000000000b2','22222222-0000-0000-0000-000000000002','support',1,null);
insert into attendance (position_id, profile_id, status) values
('11111111-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000c1','attended'),
('11111111-0000-0000-0000-0000000000a2','00000000-0000-0000-0000-0000000000c2','no_show'),
('22222222-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000d1','attended');
insert into absences (position_id, profile_id, studio_id, due_at, reason, explanation, evidence_path, submitted_at)
select '11111111-0000-0000-0000-0000000000a2','00000000-0000-0000-0000-0000000000c2', id, now()+interval '4 days','medical','fever MC', id||'/00000000-0000-0000-0000-0000000000c2/mc.jpg', now() from studios where code='BGS';
insert into check_ins (studio_id, profile_id) select id,'00000000-0000-0000-0000-0000000000c1' from studios where code='BGS';
insert into check_ins (studio_id, profile_id) select id,'00000000-0000-0000-0000-0000000000d1' from studios where code='SBJ';
insert into notifications (profile_id,title) select id,'hello '||full_name from profiles;
insert into pt_sessions (studio_id, coach_id, client_name, session_date, amount_paid, coach_pct, status)
select s.id, x.c::uuid, 'Client of '||x.c, current_date, 200, 50, 'approved' from studios s join (values
 ('BGS','00000000-0000-0000-0000-0000000000c1'),('BGS','00000000-0000-0000-0000-0000000000c2'),('SBJ','00000000-0000-0000-0000-0000000000d1')) x(code,c) on s.code=x.code;
insert into challenges (id, studio_id, pay_month, revenue, coach_pct)
select x.id::uuid, s.id, '2026-11-01', 10000, 50 from studios s join (values ('BGS','33333333-0000-0000-0000-000000000001'),('SBJ','33333333-0000-0000-0000-000000000002')) x(code,id) on s.code=x.code;
insert into challenge_coaches (challenge_id, profile_id, share_pct) values
('33333333-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1',60),
('33333333-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c2',40),
('33333333-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000d1',100);
insert into coach_reviews (profile_id, studio_id, reviewer_id, care_and_concern, technique, english, ice_breaking, talk_time, comments)
select x.p::uuid, s.id, x.r::uuid, 5,5,5,5,5,'review of '||x.p from studios s join (values
 ('BGS','00000000-0000-0000-0000-0000000000c1','00000000-0000-0000-0000-0000000000b1'),
 ('BGS','00000000-0000-0000-0000-0000000000c2','00000000-0000-0000-0000-0000000000b1'),
 ('SBJ','00000000-0000-0000-0000-0000000000d1','00000000-0000-0000-0000-0000000000b2')) x(code,p,r) on s.code=x.code;
insert into swap_requests (position_id, from_id, to_id) values ('22222222-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000d1','00000000-0000-0000-0000-0000000000c2');

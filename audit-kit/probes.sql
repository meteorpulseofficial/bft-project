\set QUIET 1
\pset tuples_only on
\pset format unaligned
\set ON_ERROR_STOP 0
\set c1 '''00000000-0000-0000-0000-0000000000c1'''
\set c2 '''00000000-0000-0000-0000-0000000000c2'''
\set b1 '''00000000-0000-0000-0000-0000000000b1'''
\set d1 '''00000000-0000-0000-0000-0000000000d1'''
\echo P1 coach c1 direct UPDATE positions (claim future lead bypassing RPC)
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:c1,true) \g /dev/null
with u as (update public.positions set coach_id=:c1 where id='11111111-0000-0000-0000-0000000000b1' returning 1) select 'rows updated='||count(*) from u;
rollback;
\echo P2 coach c2 INSERT attendance attended for own no-show position
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
insert into public.attendance(position_id,profile_id,status) values ('11111111-0000-0000-0000-0000000000a2',:c2,'attended') on conflict (position_id) do update set status='attended';
rollback;
\echo P3 coach c2 UPDATE own studio_members is_lead=true
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
with u as (update public.studio_members set is_lead=true where profile_id=:c2 returning 1) select 'rows updated='||count(*) from u;
rollback;
\echo P4 coach c1 INSERT pt at 100pct approved; read back status/pct
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:c1,true) \g /dev/null
insert into public.pt_sessions(studio_id,coach_id,client_name,session_date,amount_paid,coach_pct,status) select id,:c1,'x',current_date,100,100,'approved' from public.studios where code='BGS' returning status, coach_pct, coach_amount;
rollback;
\echo P5 BGS mgr b1 calls set_attendance / assign / verify / cancel on SBJ
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
select public.set_attendance('22222222-0000-0000-0000-0000000000a1','no_show',0,false);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
select public.assign_position('22222222-0000-0000-0000-0000000000b2',:c2);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
select public.verify_class('22222222-0000-0000-0000-000000000001',10);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
select public.set_class_cancelled('22222222-0000-0000-0000-000000000002',true);
rollback;
\echo P6 BGS mgr b1 direct UPDATE positions: put SBJ-only coach d1 into BGS Lead, and non-Lead c2 into Lead
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
with u as (update public.positions set coach_id=:d1 where id='11111111-0000-0000-0000-0000000000b1' returning id, coach_id) select 'd1 into BGS lead: '||count(*) from u;
with u as (update public.positions set coach_id=:c2 where id='11111111-0000-0000-0000-0000000000a1' returning id) select 'c2 (not Lead) into past BGS lead: '||count(*) from u;
rollback;
\echo P7 BGS mgr b1 direct UPDATE classes (uncancel/verify silently, change start time of past class)
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
with u as (update public.classes set verified_at=now(), headcount=99, starts_at=starts_at+interval '3 days' where id='11111111-0000-0000-0000-000000000001' returning 1) select 'rows='||count(*) from u;
rollback;
\echo P8 BGS mgr marks attended on a CANCELLED class
begin; update classes set status='cancelled' where id='11111111-0000-0000-0000-000000000001';
set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
select public.set_attendance('11111111-0000-0000-0000-0000000000a1','attended',0,false);
select 'class status='||c.status||' att='||a.status from public.attendance a join public.positions p on p.id=a.position_id join public.classes c on c.id=p.class_id where a.position_id='11111111-0000-0000-0000-0000000000a1';
rollback;
\echo P9 after verify_class locks the class, mgr changes attended->no_show and back
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
select public.set_attendance('11111111-0000-0000-0000-0000000000a2','attended',0,true);
select 'open='||public.verify_class('11111111-0000-0000-0000-000000000001',12);
select public.set_attendance('11111111-0000-0000-0000-0000000000a1','no_show',0,false);
select 'verified_at set='||(c.verified_at is not null)||' att now='||a.status from public.classes c, public.attendance a where c.id='11111111-0000-0000-0000-000000000001' and a.position_id='11111111-0000-0000-0000-0000000000a1';
rollback;
\echo P10 BGS mgr b1 logs PT for himself at 100pct approved (also as a BGS coach)
begin; insert into studio_members(studio_id,profile_id,role) select id,'00000000-0000-0000-0000-0000000000b1','coach' from studios where code='BGS';
set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
insert into public.pt_sessions(studio_id,coach_id,client_name,session_date,amount_paid,coach_pct,status) select id,:b1,'self',current_date,500,100,'approved' from public.studios where code='BGS' returning 'status='||status||' pct='||coach_pct||' coach_amount='||coach_amount||' reviewed_by=self:'||(reviewed_by=auth.uid());
rollback;
\echo P11 mgr edits APPROVED pt amount afterwards
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
with u as (update public.pt_sessions set amount_paid=2000, coach_pct=90 where coach_id=:c1 and status='approved' returning status, coach_amount) select 'after edit: '||status||' '||coach_amount from u;
rollback;
\echo P12 coach c1 moves own pending PT to SBJ (not a member there)
begin; insert into pt_sessions(id,studio_id,coach_id,client_name,session_date,amount_paid,coach_pct) select '44444444-0000-0000-0000-000000000001',id,'00000000-0000-0000-0000-0000000000c1','p',current_date,100,50 from studios where code='BGS';
set local role authenticated; select set_config('request.jwt.claim.sub',:c1,true) \g /dev/null
with u as (update public.pt_sessions set studio_id=(select id from studios where code='SBJ') where id='44444444-0000-0000-0000-000000000001' returning 1) select 'rows='||count(*) from u;
rollback;
\echo P13 coach c1 calls helper functions about OTHER people / studios
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:c1,true) \g /dev/null
select 'strike_count(c2,BGS)='||public.strike_count(:c2,(select id from studios where code='BGS')) ;
select 'swap_blocker reveals d1 schedule: '||coalesce(public.swap_blocker('11111111-0000-0000-0000-0000000000b2',:d1),'null');
select 'fmt_class(SBJ class)='||public.fmt_class('22222222-0000-0000-0000-000000000001');
select 'reliability(SBJ) rows='||count(*) from public.reliability_scores((select id from studios where code='SBJ'));
select 'can_manage_person(c2)='||public.can_manage_person(:c2);
rollback;
\echo P14 BGS mgr reads/writes own private note; SBJ coach d1 notes
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
with u as (update public.profile_notes set notes='edited by self' where profile_id=:b1 returning 1) select 'own note rows updated='||count(*) from u;
select 'd1 note visible='||count(*) from public.profile_notes where profile_id=:d1;
rollback;
\echo P15 BGS mgr updates SBJ-only coach d1 contacts
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
with u as (update public.profile_contacts set phone='x' where profile_id=:d1 returning 1) select 'rows='||count(*) from u;
rollback;
\echo P17 BGS mgr direct UPDATE studio_members on SBJ / add d1 to BGS
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
with u as (update public.studio_members set is_lead=true where profile_id=:c2 and studio_id=(select id from studios where code='SBJ') returning 1) select 'SBJ rows='||count(*) from u;
rollback;
\echo P18 challenge shares can exceed 100pct of the pool
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
insert into public.challenge_coaches(challenge_id,profile_id,share_pct) values ('33333333-0000-0000-0000-000000000001',:b1,50);
select 'pool='||(c.revenue*c.coach_pct/100)||' paid='||sum(cc.amount)||' shares='||sum(cc.share_pct) from public.challenges c join public.challenge_coaches cc on cc.challenge_id=c.id where c.id='33333333-0000-0000-0000-000000000001' group by c.revenue,c.coach_pct;
rollback;
\echo P21 coach submits absence explanation AFTER the deadline; strike count before/after
begin; update absences set submitted_at=null, reason=null, explanation=null, due_at=now()-interval '1 day';
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select 'strikes before='||public.strike_count(:c2,(select id from studios where code='BGS'));
select public.submit_absence((select id from public.absences limit 1),'other','overslept late reply','');
select 'strikes after late submit='||public.strike_count(:c2,(select id from studios where code='BGS'));
rollback;
\echo P25 BGS mgr writes a review about SBJ-only coach d1
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:b1,true) \g /dev/null
insert into public.coach_reviews(profile_id,studio_id,care_and_concern,technique,english,ice_breaking,talk_time) select :d1,id,1,1,1,1,1 from public.studios where code='BGS' returning 'inserted review on d1';
rollback;
\echo P26 finance writes? approve PT / update studios rates
begin; set local role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000a2',true) \g /dev/null
with u as (update public.pt_sessions set status='rejected' returning 1) select 'fin pt rows='||count(*) from u;
with u as (update public.studios set lead_rate=1 returning 1) select 'fin studio rows='||count(*) from u;
rollback;
\echo P27 coach updates own notification text
begin; set local role authenticated; select set_config('request.jwt.claim.sub',:c1,true) \g /dev/null
with u as (update public.notifications set title='forged' returning 1) select 'rows='||count(*) from u;
rollback;
\echo P28 anon role: select profiles / call functions
begin; set local role anon;
select 'anon profiles='||count(*) from public.profiles;
select 'anon fmt_class='||coalesce(public.fmt_class('22222222-0000-0000-0000-000000000001'),'null');
select 'anon strike_count='||public.strike_count('00000000-0000-0000-0000-0000000000c2',(select '00000000-0000-0000-0000-000000000000'::uuid));
rollback;

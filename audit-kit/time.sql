\set c2 '''00000000-0000-0000-0000-0000000000c2'''
-- helper: make a BGS class for c2 starting at offset from now(), return pos id
create or replace function pg_temp.mk(off interval, dur int default 55) returns uuid language plpgsql as $$
declare c uuid := gen_random_uuid(); p uuid := gen_random_uuid(); begin
 insert into classes(id,studio_id,class_type_id,starts_at,duration_min) select c,s.id,(select id from class_types where studio_id=s.id limit 1), now()+off, dur from studios s where code='BGS';
 insert into positions(id,class_id,role,seq,coach_id) values (p,c,'support',1,'00000000-0000-0000-0000-0000000000c2'); return p; end $$;
\echo RUN gap 179/180/181 (A starts now+10m, 55 min; B starts A_end+gap)
select g, (select string_agg(x,'') from (select 1) q, lateral (select '') y(x)) from generate_series(1,0) g;
begin; select pg_temp.mk(interval '10 min') as a \gset
select pg_temp.mk(interval '10 min' + interval '55 min' + interval '179 min') as b \gset
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select public.check_in((select checkin_token from studios where code='BGS')) \g /dev/null
select 'gap 179: B covered='||exists(select 1 from attendance where position_id=:'b'); rollback;
begin; select pg_temp.mk(interval '10 min') as a \gset
select pg_temp.mk(interval '10 min' + interval '55 min' + interval '180 min') as b \gset
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select public.check_in((select checkin_token from studios where code='BGS')) \g /dev/null
select 'gap 180: B covered='||exists(select 1 from attendance where position_id=:'b'); rollback;
begin; select pg_temp.mk(interval '10 min') as a \gset
select pg_temp.mk(interval '10 min' + interval '55 min' + interval '181 min') as b \gset
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select public.check_in((select checkin_token from studios where code='BGS')) \g /dev/null
select 'gap 181: B covered='||exists(select 1 from attendance where position_id=:'b'); rollback;
begin; select pg_temp.mk(interval '60 min') as a \gset
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select 'class starts in 60 min: check_in -> '||(public.check_in((select checkin_token from studios where code='BGS'))->>'minutes_late')||' min late'; rollback;
begin; select pg_temp.mk(interval '60 min 1 sec') as a \gset
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select 'class starts in 60 min 1 sec: check_in -> '||(public.check_in((select checkin_token from studios where code='BGS'))->>'minutes_late')||' min late'; rollback;
begin; select pg_temp.mk(interval '20 min') as a \gset
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select 'class starts in 20 min: '||(public.check_in((select checkin_token from studios where code='BGS'))::text); rollback;
begin; select pg_temp.mk(interval '19 min 59 sec') as a \gset
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select 'class starts in 19 min 59 sec: '||(public.check_in((select checkin_token from studios where code='BGS'))::text); rollback;
begin; select pg_temp.mk(interval '19 min') as a \gset
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select 'class starts in 19 min: '||(public.check_in((select checkin_token from studios where code='BGS'))::text); rollback;
begin; select pg_temp.mk(interval '24 hours') as a \gset
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select public.drop_position(:'a'); select 'drop at start-24 hours: dropped='||((select coach_id from positions where id=:'a') is null); rollback;
begin; select pg_temp.mk(interval '24 hours 1 sec') as a \gset
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select public.drop_position(:'a'); select 'drop at start-24 hours 1 sec: dropped='||((select coach_id from positions where id=:'a') is null); rollback;
begin; select pg_temp.mk(interval '23 hours 59 min') as a \gset
set local role authenticated; select set_config('request.jwt.claim.sub',:c2,true) \g /dev/null
select public.drop_position(:'a'); select 'drop at start-23 hours 59 min: dropped='||((select coach_id from positions where id=:'a') is null); rollback;
\echo full-time coach c3 drops a manager-assigned class (claim blocked for FT, drop not)
begin; update positions set coach_id='00000000-0000-0000-0000-0000000000c3' where id='11111111-0000-0000-0000-0000000000b2';
set local role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000c3',true) \g /dev/null
select public.drop_position('11111111-0000-0000-0000-0000000000b2'); select 'FT dropped='||((select coach_id from positions where id='11111111-0000-0000-0000-0000000000b2') is null); rollback;
\echo explain window counts from when manager marks, not the class: class 20 days ago marked today
begin; select pg_temp.mk(interval '-20 days') as a \gset
set local role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000b1',true) \g /dev/null
select public.set_attendance(:'a','no_show',0,false);
select 'class '||to_char(c.starts_at at time zone 'Asia/Kuala_Lumpur','DD Mon')||' due '||to_char(a.due_at at time zone 'Asia/Kuala_Lumpur','DD Mon') from absences a join positions p on p.id=a.position_id join classes c on c.id=p.class_id where a.position_id=:'a'; rollback;
\echo strike window measured from marking time: no-show class 100 days ago, marked invalid today
begin; select pg_temp.mk(interval '-100 days') as a \gset
insert into absences(position_id,profile_id,studio_id,due_at,decision) select :'a','00000000-0000-0000-0000-0000000000c2',id,now()-interval '1 day','invalid' from studios where code='BGS';
select 'strikes incl 100-day-old class='||strike_count('00000000-0000-0000-0000-0000000000c2',(select id from studios where code='BGS')); rollback;
\echo strike invalid then manager flips attendance to attended: strike remains
begin; select pg_temp.mk(interval '-2 days') as a \gset
set local role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000b1',true) \g /dev/null
select public.set_attendance(:'a','no_show',0,false);
select public.decide_absence((select id from absences where position_id=:'a'),false,'');
select public.set_attendance(:'a','attended',0,false);
select 'att='||(select status from attendance where position_id=:'a')||' absence decision still='||(select decision from absences where position_id=:'a'); rollback;

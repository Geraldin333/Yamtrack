-- seed.sql: datos de ejemplo + vista v_tracking
-- Requiere al menos 1 usuario registrado en users_user.
-- Ejecutar una sola vez (si se repite, duplica los datos).

create temp table _u as select array_agg(id order by id) ids from users_user;

-- ITEMS (metadatos)
insert into app_item(media_id,media_type,title,image,season_number,episode_number,source)
select (1000+g)::text,'movie','Película '||g,'none',null,null,'tmdb' from generate_series(1,40) g;
insert into app_item(media_id,media_type,title,image,season_number,episode_number,source)
select (2000+g)::text,'tv','Serie '||g,'none',null,null,'tmdb' from generate_series(1,30) g;
insert into app_item(media_id,media_type,title,image,season_number,episode_number,source)
select (2000+g)::text,'season','Serie '||g,'none',1,null,'tmdb' from generate_series(1,30) g;
insert into app_item(media_id,media_type,title,image,season_number,episode_number,source)
select (2000+g)::text,'episode','Serie '||g,'none',1,e,'tmdb'
from generate_series(1,30) g, generate_series(1,2) e where e=1 or g<=15;
insert into app_item(media_id,media_type,title,image,season_number,episode_number,source)
select (3000+g)::text,'anime','Anime '||g,'none',null,null,'mal' from generate_series(1,30) g;
insert into app_item(media_id,media_type,title,image,season_number,episode_number,source)
select (4000+g)::text,'game','Juego '||g,'none',null,null,'igdb' from generate_series(1,30) g;

-- MOVIE / ANIME / GAME
do $$
declare mt text; mx int;
begin
  foreach mt in array array['movie','anime','game'] loop
    mx := case mt when 'movie' then 1 when 'anime' then 24 else 80 end;
    execute format($f$
      insert into app_%1$s(score,status,end_date,notes,user_id,start_date,progress,item_id,progressed_at,created_at)
      select round((3+random()*7)::numeric,1), t.status,
        case when t.status='Completed' then least(now(), t.d + interval '10 days') end,
        '', t.uid, t.d,
        case when t.status='Completed' then %2$s else floor(random()*%2$s)::int end,
        t.item_id, t.d, t.d
      from (select i.id item_id,
              (array['Completed','Completed','Completed','In progress','Planning','Paused','Dropped'])[1+floor(random()*7)::int] status,
              now() - (random()*365||' days')::interval d,
              (select ids[1+(i.id %% array_length(ids,1))::int] from _u) uid
            from app_item i where i.media_type=%1$L offset 0) t
    $f$, mt, mx);
  end loop;
end $$;

-- TV
insert into app_tv(score,notes,user_id,status,item_id,created_at)
select round((3+random()*7)::numeric,1), '', t.uid, t.status, t.item_id, t.d
from (select i.id item_id,
        (array['Completed','Completed','In progress','In progress','Planning','Paused','Dropped'])[1+floor(random()*7)::int] status,
        now() - (random()*365||' days')::interval d,
        (select ids[1+(i.id % array_length(ids,1))::int] from _u) uid
      from app_item i where i.media_type='tv' offset 0) t;

-- SEASON (1 por serie, mismo usuario)
insert into app_season(score,status,notes,user_id,related_tv_id,item_id,created_at)
select round((3+random()*7)::numeric,1), tv.status, '', tv.user_id, tv.id, si.id, tv.created_at
from app_tv tv
join app_item ti on ti.id=tv.item_id
join app_item si on si.media_type='season' and si.media_id=ti.media_id and si.source=ti.source;

-- EPISODE
insert into app_episode(end_date,related_season_id,item_id,created_at)
select least(now(), s.created_at + (ei.episode_number||' days')::interval), s.id, ei.id, s.created_at
from app_season s
join app_item si on si.id=s.item_id
join app_item ei on ei.media_type='episode' and ei.media_id=si.media_id
  and ei.source=si.source and ei.season_number=si.season_number;

-- EVENTS (calendario)
insert into events_event(content_number,datetime,item_id,notification_sent)
select c, now() + ((random()*120-60)||' days')::interval, i.id, false
from app_item i cross join generate_series(1,2) c
where i.media_type='anime' and (c=1 or i.id % 3 = 0);
update events_event set notification_sent = (datetime < now());

-- LISTAS
insert into lists_customlist(name,description,owner_id)
select 'Lista '||g, 'Lista de ejemplo '||g, ids[1+(g % array_length(ids,1))] from _u, generate_series(1,10) g;
insert into lists_customlistitem(date_added,custom_list_id,item_id)
select now() - (random()*200||' days')::interval, l.id, i.id
from (select id, row_number() over(order by id)-1 ln from lists_customlist) l
join (select id, row_number() over(order by id) rn from app_item where media_type in ('movie','anime','game')) i
  on l.ln = i.rn % 10
where i.rn <= 50;

-- VISTA PARA LOOKER
create or replace view v_tracking with (security_invoker = true) as
select 'movie' tipo, u.username usuario, i.title titulo, m.status estado, m.score puntaje, m.progress progreso, m.created_at::date fecha
from app_movie m join app_item i on i.id=m.item_id join users_user u on u.id=m.user_id
union all
select 'anime', u.username, i.title, m.status, m.score, m.progress, m.created_at::date
from app_anime m join app_item i on i.id=m.item_id join users_user u on u.id=m.user_id
union all
select 'game', u.username, i.title, m.status, m.score, m.progress, m.created_at::date
from app_game m join app_item i on i.id=m.item_id join users_user u on u.id=m.user_id
union all
select 'tv', u.username, i.title, m.status, m.score, null::int, m.created_at::date
from app_tv m join app_item i on i.id=m.item_id join users_user u on u.id=m.user_id;
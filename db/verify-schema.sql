-- 核對正式環境的實際結構與 supabase-schema.sql 宣稱的是否一致。純唯讀。
--
-- 【怎麼用】
--   1. Supabase 後台 → SQL Editor → 貼上整份 → 按 Run
--   2. 結果只有「一格」。點那一格,Ctrl+C,整段貼回對話即可。
--      不必框選表格,也不必貼這份查詢本身。
--
-- 期望看到「完全一致」。若列出差異,照貼即可,我會據此修正 supabase-schema.sql。
--
-- 若已執行 20260804_add_updated_at.sql,clubs/venues/events/subs 會多出
-- updated_at,會被列為「實際有,文件沒寫」——那是預期內的,不是問題。

with documented(table_name, column_name, data_type) as (values
  ('clubs','area','text'),
    ('clubs','bands','integer'),
    ('clubs','contact','text'),
    ('clubs','created_at','timestamp with time zone'),
    ('clubs','genre','text'),
    ('clubs','id','uuid'),
    ('clubs','intro','text'),
    ('clubs','members','integer'),
    ('clubs','name','text'),
    ('clubs','user_id','uuid'),
    ('edit_keys','code','text'),
    ('edit_keys','item_id','uuid'),
    ('edit_keys','item_table','text'),
    ('events','contact','text'),
    ('events','created_at','timestamp with time zone'),
    ('events','date','date'),
    ('events','descr','text'),
    ('events','host','text'),
    ('events','id','uuid'),
    ('events','state','text'),
    ('events','time','text'),
    ('events','title','text'),
    ('events','user_id','uuid'),
    ('events','venue','text'),
    ('photography','area','text'),
    ('photography','contact','text'),
    ('photography','created_at','timestamp with time zone'),
    ('photography','id','uuid'),
    ('photography','name','text'),
    ('photography','note','text'),
    ('photography','price','text'),
    ('posts','body','text'),
    ('posts','club','text'),
    ('posts','contact','text'),
    ('posts','created_at','timestamp with time zone'),
    ('posts','id','uuid'),
    ('posts','kind','text'),
    ('posts','title','text'),
    ('posts','user_id','uuid'),
    ('subs','contact','text'),
    ('subs','created_at','timestamp with time zone'),
    ('subs','event_clubs','text'),
    ('subs','event_name','text'),
    ('subs','event_time_place','text'),
    ('subs','expires_at','timestamp with time zone'),
    ('subs','filled','boolean'),
    ('subs','id','uuid'),
    ('subs','note','text'),
    ('subs','reminder_sent_at','timestamp with time zone'),
    ('subs','song','text'),
    ('subs','tags','ARRAY'),
    ('subs','user_id','uuid'),
    ('venue_apps','club','text'),
    ('venue_apps','contact','text'),
    ('venue_apps','created_at','timestamp with time zone'),
    ('venue_apps','event_date','date'),
    ('venue_apps','id','uuid'),
    ('venue_apps','note','text'),
    ('venue_apps','size','text'),
    ('venue_apps','state','text'),
    ('venue_apps','venue','text'),
    ('venues','area','text'),
    ('venues','cap','integer'),
    ('venues','created_at','timestamp with time zone'),
    ('venues','id','uuid'),
    ('venues','name','text'),
    ('venues','note','text'),
    ('venues','price','text'),
    ('venues','contact','text')
),
actual as (
  select table_name, column_name, data_type
  from information_schema.columns
  where table_schema = 'public'
),
diff as (
  select
    coalesce(d.table_name, a.table_name)   as t,
    coalesce(d.column_name, a.column_name) as c,
    case
      when a.column_name is null then '文件有寫,實際不存在'
      when d.column_name is null then '實際有,文件沒寫'
      else '型別不符:文件寫 ' || d.data_type || ',實際是 ' || a.data_type
    end as problem
  from documented d
  full join actual a
    on d.table_name = a.table_name and d.column_name = a.column_name
  where a.column_name is null
     or d.column_name is null
     or d.data_type <> a.data_type
),
extra_tables as (
  select t.table_name as tn
  from information_schema.tables t
  where t.table_schema = 'public' and t.table_type = 'BASE TABLE'
    and t.table_name not in (select distinct d.table_name from documented d)
)
select
  E'=== BandLink schema 核對結果 ===\n'
  || 'PostgreSQL ' || current_setting('server_version')
  || '  /  ' || now()::timestamp(0)::text || E'\n\n'
  || case when (select count(*) from diff) = 0
          then E'[欄位] 完全一致,supabase-schema.sql 與正式環境相符\n'
          else '[欄位] 差異 ' || (select count(*) from diff)::text || E' 項:\n'
               || (select string_agg('  ' || t || '.' || c || '  ->  ' || problem,
                                     E'\n' order by t, c) from diff) || E'\n'
     end
  || case when (select count(*) from extra_tables) = 0
          then E'[表]   沒有文件未收錄的表\n'
          else E'[表]   文件完全沒收錄:\n'
               || (select string_agg('  ' || tn, E'\n' order by tn) from extra_tables) || E'\n'
     end
  -- 只列 public schema。正式環境的 pg_stat_user_tables 會包含 auth / storage 等
  -- Supabase 內部 schema 的數十張表,全列出來會把結果灌爆。
  -- auth.users 另外單獨補一列,因為那就是「總註冊帳號數」。
  || E'\n[筆數] 各表實際列數:\n'
  || coalesce((select string_agg('  ' || tbl || ': ' || cnt::text, E'\n' order by tbl)
               from (
                 select 'clubs' tbl, count(*) cnt from clubs
                 union all select 'events',      count(*) from events
                 union all select 'venues',      count(*) from venues
                 union all select 'subs',        count(*) from subs
                 union all select 'photography', count(*) from photography
                 union all select 'posts',       count(*) from posts
                 union all select 'venue_apps',  count(*) from venue_apps
                 union all select 'edit_keys',   count(*) from edit_keys
                 union all select 'auth.users',  count(*) from auth.users
               ) x), '  (無)')
  as 核對結果;

-- 核對正式環境的實際結構與 supabase-schema.sql 宣稱的是否一致。
-- 純唯讀。在 Supabase SQL Editor 貼上整份執行,只會回傳一張小表。
--
-- 期望結果:「✅ 完全一致」一列。
-- 若有任何一列不是 ✅,把整張表貼回來即可,不必貼完整 schema dump。
--
-- 特別要看的是 subs 與 photography 這兩張表——supabase-schema.sql 裡
-- 它們的欄位是從 src/App.jsx 與 api/remind-subs.js 反推的,從未核對過。
--
-- ⚠️ 若已執行 20260804_add_updated_at.sql,clubs/venues/events/subs 會多出
--    updated_at,那會顯示為「文件沒寫但實際有」,屬預期內,不是問題。

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
    ('venues','tags','text')
),
actual as (
  select table_name, column_name, data_type
  from information_schema.columns
  where table_schema = 'public'
),
diff as (
  select
    coalesce(d.table_name, a.table_name)   as table_name,
    coalesce(d.column_name, a.column_name) as column_name,
    case
      when a.column_name is null then '❌ 文件有寫,實際不存在'
      when d.column_name is null then '⚠️ 實際有,文件沒寫'
      else '❌ 型別不符:文件寫 ' || d.data_type || ',實際是 ' || a.data_type
    end as problem
  from documented d
  full join actual a
    on d.table_name = a.table_name and d.column_name = a.column_name
  where a.column_name is null
     or d.column_name is null
     or d.data_type <> a.data_type
)
select table_name, column_name, problem from diff
union all
select '✅ 完全一致', '', 'supabase-schema.sql 與正式環境相符,無須修正'
where not exists (select 1 from diff)
order by table_name, column_name;

-- 讀出正式環境目前的真實結構,用來核對 supabase-schema.sql 有沒有落後。
-- 在 Supabase 主控台的 SQL Editor 執行,把輸出貼回來就能對。
-- 純唯讀,不會改到任何資料。

-- 1. 所有表的所有欄位
select table_name, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
order by table_name, ordinal_position;

-- 2. 各表資料筆數(估計值,由 Postgres 統計資訊而來,不是精確 count)
select relname as table_name, n_live_tup as row_count
from pg_stat_user_tables
order by n_live_tup desc;

-- 3. 外鍵一覽——目前預期是「幾乎沒有」,這正是 metrics.sql 只能做文字比對的原因
select
  tc.table_name,
  kcu.column_name,
  ccu.table_name  as references_table,
  ccu.column_name as references_column
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on kcu.constraint_name = tc.constraint_name
join information_schema.constraint_column_usage ccu
  on ccu.constraint_name = tc.constraint_name
where tc.constraint_type = 'FOREIGN KEY'
  and tc.table_schema = 'public'
order by tc.table_name;

-- 4. RLS 開關與 policy 數量——確認每張表都有擋好
select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  count(p.polname) as policy_count
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_policy p on p.polrelid = c.oid
where n.nspname = 'public' and c.relkind = 'r'
group by c.relname, c.relrowsecurity
order by c.relname;

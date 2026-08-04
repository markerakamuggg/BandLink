-- 團聚 BandLink 現況快照
-- 在 Supabase SQL Editor 貼上整份執行,只回傳「一張窄表」,整張複製貼回來就好。
-- 純唯讀,不會改到任何資料。
--
-- 這份是 metrics.sql 的濃縮版:同樣的問題,但壓成一次一張表,方便交換。
-- 想看逐筆明細(社團名單、host 長相、每週趨勢)再去跑 metrics.sql。
--
-- 不必先跑 migration 也能用:與 updated_at 相關的指標會自動顯示「尚未啟用」。

with
u as (select * from auth.users),
c as (select * from clubs),
e as (select * from events),
s as (select * from subs),

-- to_jsonb 取欄位:updated_at 不存在時回傳 NULL 而不是報錯,
-- 所以這份查詢在跑 migration 前後都能用
c_upd as (
  select (to_jsonb(c) ->> 'updated_at')::timestamptz as updated_at, c.created_at
  from clubs c
),

m(ord, 分類, 指標, 數值) as (values

  (1,  '帳號', '總註冊數',
       (select count(*)::text from u)),
  (2,  '帳號', '註冊後從未登入',
       (select count(*) filter (where last_sign_in_at is null)::text from u)),
  (3,  '帳號', '曾在註冊隔天後再登入',
       (select count(*) filter (where last_sign_in_at > created_at + interval '1 day')::text from u)),
  (4,  '帳號', '7 天內登入過',
       (select count(*) filter (where last_sign_in_at > now() - interval '7 days')::text from u)),
  (5,  '帳號', '30 天內登入過(含上一列)',
       (select count(*) filter (where last_sign_in_at > now() - interval '30 days')::text from u)),
  (6,  '帳號', '超過 30 天沒登入',
       (select count(*) filter (where last_sign_in_at <= now() - interval '30 days')::text from u)),

  (10, '內容量', '社團',      (select count(*)::text from c)),
  (11, '內容量', '活動',      (select count(*)::text from e)),
  (12, '內容量', '場地',      (select count(*)::text from venues)),
  (13, '內容量', '代打貼文',  (select count(*)::text from s)),
  (14, '內容量', '攝影',      (select count(*)::text from photography)),

  (20, '近期動能', '近 7 天新增社團',
       (select count(*) filter (where created_at > now() - interval '7 days')::text from c)),
  (21, '近期動能', '近 30 天新增社團',
       (select count(*) filter (where created_at > now() - interval '30 days')::text from c)),
  (22, '近期動能', '近 7 天新增活動',
       (select count(*) filter (where created_at > now() - interval '7 days')::text from e)),
  (23, '近期動能', '近 30 天新增活動',
       (select count(*) filter (where created_at > now() - interval '30 days')::text from e)),
  (24, '近期動能', '最後一筆活動建於',
       (select coalesce(max(created_at)::date::text, '(無)') from e)),

  (30, '活動', '未來場次',
       (select count(*) filter (where date >= current_date)::text from e)),
  (31, '活動', '已過期場次',
       (select count(*) filter (where date < current_date)::text from e)),
  (32, '活動', '最早 / 最晚日期',
       (select coalesce(min(date)::text,'(無)') || ' / ' || coalesce(max(date)::text,'(無)') from e)),
  (33, '活動', '沒填時間的場次',
       (select count(*) filter (where time is null or trim(time) = '')::text from e)),
  (34, '活動', '狀態為開放報名',
       (select count(*) filter (where state = '開放報名')::text from e)),

  (40, '代打', '已徵到人',
       (select count(*) filter (where filled)::text from s)),
  (41, '代打', '過期仍沒徵到',
       (select count(*) filter (where expires_at < now() and not filled)::text from s)),
  (42, '代打', '徵到人比例 %',
       (select coalesce(round(100.0 * count(*) filter (where filled)
              / nullif(count(*),0), 1)::text, '(無資料)') from s)),

  -- 以下三項靠名稱比對,是估計值,判讀方式見 README
  (50, '比對品質【估計】', '比對到活動的社團數 / 總社團數',
       (select count(*) filter (where exists (
                select 1 from e where e.host ilike '%' || c.name || '%'))::text
             || ' / ' || count(*)::text from c)),
  (51, '比對品質【估計】', '主辦欄對不到任何社團的活動數',
       (select count(*) filter (where not exists (
                select 1 from c where e.host ilike '%' || c.name || '%'))::text from e)),
  (52, '比對品質【估計】', '場地對得上場地表的活動數',
       (select count(*) filter (where exists (
                select 1 from venues v where e.venue ilike '%' || v.name || '%'))::text from e)),

  (60, '編輯行為', '建檔逾 10 分鐘後被改過的社團',
       (select case when count(*) filter (where updated_at is not null) = 0
                    then '(尚未啟用:需先跑 20260804_add_updated_at.sql)'
                    else count(*) filter (where updated_at > created_at + interval '10 minutes')::text
               end from c_upd)),
  (61, '編輯行為', '尚未認領的舊資料(會灌水上一列)',
       (select count(*)::text from edit_keys))
)
select 分類, 指標, 數值 from m order by ord;

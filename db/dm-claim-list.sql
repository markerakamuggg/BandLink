-- 認領 DM 名單:把 37 筆未認領舊資料變成一份「照表操課」的私訊清單。
-- 純唯讀,不會改到任何資料。
--
-- 【怎麼用】
--   Supabase 後台 → SQL Editor → 貼上整份 → Run → 結果只有一格,
--   點開複製,每一則訊息已代入社團名與認領碼,照著逐一 DM 即可。
--
-- ⚠️ 認領碼等同該筆資料的編輯權,只私訊給該社團自己的官方帳號,
--    不要公開張貼,也不要一次貼給多個社團。
--
-- 發送建議:一天發 10~15 則就好,分三天發完。全新 IG 帳號短時間
-- 大量 DM 陌生帳號會被判定騷擾而限制功能。

with claim_clubs as (
  select k.code, c.name, coalesce(nullif(trim(c.contact), ''), '(未留聯絡方式)') as contact,
         row_number() over (order by c.created_at) as rn
  from edit_keys k
  join clubs c on c.id = k.item_id
  where k.item_table = 'clubs'
),
claim_events as (
  select k.code, e.title, e.host,
         coalesce(nullif(trim(e.contact), ''), '(未留聯絡方式,可從主辦社團找)') as contact,
         row_number() over (order by e.created_at) as rn
  from edit_keys k
  join events e on e.id = k.item_id
  where k.item_table = 'events'
)
select
  E'=== 認領 DM 名單 ===\n'
  || '產生時間:' || now()::timestamp(0)::text || E'\n\n'
  || '◆ 社團(' || (select count(*) from claim_clubs)::text || E' 筆)\n'
  || E'──────────────────────────────\n'
  || coalesce((select string_agg(
       '【' || rn || '】傳給:' || contact || E'\n'
       || '嗨!這裡是「團聚 BandLink」band-link.vercel.app,雙北熱音社的演出互聯平台。'
       || name || '之前已經登錄在團聚的社團名錄上囉!這組是你們社團的認領碼:'
       || code
       || '。管理者用 Google 登入後,到「代打」分頁點「以前用編輯碼發過內容?登入後在這裡認領」,輸入這組碼,社團資料就綁定到你們帳號,之後隨時能自己編輯資料、發演出、找代打。'
       || '開學季的招生跟迎新演出資訊都歡迎放上來,我們每週日會把當週雙北演出整理成 IG 貼文,幫大家一起宣傳🤘',
       E'\n\n' order by rn) from claim_clubs), '(沒有未認領的社團)')
  || E'\n\n◆ 活動(' || (select count(*) from claim_events)::text || E' 筆)\n'
  || E'──────────────────────────────\n'
  || coalesce((select string_agg(
       '【' || rn || '】傳給:' || contact || '(主辦:' || host || E')\n'
       || '嗨!這裡是「團聚 BandLink」band-link.vercel.app。你們之前發布的活動「'
       || title || '」還沒綁定帳號,認領碼是:' || code
       || '。用 Google 登入後到「代打」分頁的認領入口輸入,之後就能自己編輯或更新這場活動的資訊🤘',
       E'\n\n' order by rn) from claim_events), '(沒有未認領的活動)')
  as dm_名單;

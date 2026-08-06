-- 團聚 BandLink 使用狀況查詢
-- 在 Supabase 主控台的 SQL Editor 執行,純唯讀,不會改到任何資料。
--
-- 讀之前要知道的三個限制:
--
-- 1. events 和 clubs 之間沒有外鍵。events.host(主辦單位)是使用者自己打的自由文字,
--    表單範例就是「薇閣 × 明德」這種一場兩社團的寫法。所以「哪個社團辦過活動」只能用
--    名字去字串裡比對,會低估(社團全名與活動簡稱對不上)也會誤判(短名字誤中)。
--    凡是標著【估計】的段落,數字都是參考值不是事實,看之前先跑 6 確認 host 長相。
--
-- 2. auth.users.last_sign_in_at 只在「真的走過一次登入流程」時更新。App 用的是
--    supabase-js 預設設定(persistSession + autoRefreshToken,見 src/supabase.js),
--    同一台裝置回訪時 token 是自動續期,不會產生新的登入事件。也就是說第 2、3 段的
--    「回訪」與「活躍」是**低估值**——天天在用但沒登出過的人,看起來會像很久沒出現。
--
-- 3. 標著【需要 migration】的段落要先跑 migrations/20260804_add_updated_at.sql。
--    它問的是「有沒有回來『編輯內容』」,跟第 2 段的「有沒有回來『登入』」是兩件事。

-- ── 1. 基本量體 ──────────────────────────────────────────
select
  (select count(*) from auth.users)  as users_total,
  (select count(*) from clubs)       as clubs_total,
  (select count(*) from venues)      as venues_total,
  (select count(*) from events)      as events_total,
  (select count(*) from subs)        as subs_total,
  (select count(*) from photography) as photography_total;

-- ── 2. 帳號留存 ────────────────────────────────────────
-- ⚠️ 兩件事會讓這幾個數字加起來不等於 users_total,不是算錯:
--    (a) never_signed_in 的人 last_sign_in_at 是 NULL,不會落入任何一個活躍/沉睡分類
--    (b) active_30d 已經包含 active_7d,是包含關係不是互斥,不能相加
select
  count(*)                                                               as users_total,
  count(*) filter (where last_sign_in_at is null)                        as never_signed_in,
  count(*) filter (where last_sign_in_at > created_at + interval '1 day') as returned_at_least_once,
  count(*) filter (where last_sign_in_at > now() - interval '7 days')    as active_7d,
  count(*) filter (where last_sign_in_at > now() - interval '30 days')   as active_30d,
  count(*) filter (where last_sign_in_at <= now() - interval '30 days')  as dormant_30d
from auth.users;

-- ── 3. 每個帳號的註冊與最後登入 ──────────────────────────
-- 不含 email 等個資。⚠️ SQL Editor 預設只回傳前 1000 列,帳號數超過時要分頁看
select
  created_at::date                            as signed_up,
  last_sign_in_at::date                       as last_seen,
  (last_sign_in_at::date - created_at::date)  as days_span   -- NULL = 從未登入
from auth.users
order by created_at;

-- ── 4. 社團完整名單 ────────────────────────────────────
select * from clubs order by created_at;

-- ── 5. 活動完整名單 ────────────────────────────────────
select * from events order by date;

-- ── 6. host 實際長相(判斷第 10、11 段可不可信的依據) ──────
select host, count(*) as events
from events
group by host
order by events desc;

-- ── 7. 活動的時間分布:未來場 vs 已過期 ────────────────────
-- 沒有 start_time,日期是 date 欄位;time 是自由文字,只能檢查有沒有填
select
  count(*) filter (where date >= current_date)                as upcoming,
  count(*) filter (where date <  current_date)                as past,
  min(date)                                                   as earliest,
  max(date)                                                   as latest,
  count(*) filter (where time is null or trim(time) = '')     as missing_time,
  count(*) filter (where state = '開放報名')                   as open_for_signup
from events;

-- ── 8. 建檔節奏:活動是持續有人在建,還是早就停了 ────────────
select date_trunc('week', created_at)::date as week, count(*)
from events
group by 1
order by 1;

-- ── 9. 場地表有沒有被真的使用 【估計】──────────────────────
-- events.venue 是自由文字,跟 venues 表做名稱比對
select
  count(*)                                          as events_total,
  count(*) filter (where exists (
    select 1 from venues v where e.venue ilike '%' || v.name || '%'
  ))                                                as venue_matched
from events e;

-- ── 10. 有辦過活動的社團比例 【估計】──────────────────────
select
  count(*)                                  as clubs_total,
  count(*) filter (where e.event_count > 0) as clubs_with_events,
  round(100.0 * count(*) filter (where e.event_count > 0)
        / nullif(count(*), 0), 1)           as pct_active
from clubs c
left join lateral (
  select count(*) as event_count
  from events ev
  where ev.host ilike '%' || c.name || '%'
) e on true;

-- ── 10b. 驗證第 10 段的比對到底對不對 ──────────────────────
-- 逐一列出「每個社團比對到了哪些活動主辦欄」,用肉眼掃一遍就知道 pct_active 可不可信。
-- 在測試資料上,這個比對法同時犯了兩種錯:
--   社團「薇閣熱音社」實際辦了 host = 「薇閣 × 明德」那場 → 比對不到,被漏算
--   社團「熱音」一場都沒辦,但「明德熱音社」這個 host 裡有「熱音」兩字 → 被誤算
-- 真實資料只要有簡稱或短名字,同樣的錯就會發生。
select
  c.name                                                     as club,
  count(ev.id)                                               as matched_events,
  coalesce(string_agg(distinct ev.host, ' / '), '(比對不到)') as matched_hosts
from clubs c
left join events ev on ev.host ilike '%' || c.name || '%'
group by c.name
order by matched_events desc, c.name;

-- ── 10c. 反向檢查:哪些活動的 host 對不到任何已登錄社團 ──────
-- 這些是「有人辦活動,但主辦單位沒在社團名錄裡」或「名字寫法對不上」
select ev.host, count(*) as events
from events ev
where not exists (select 1 from clubs c where ev.host ilike '%' || c.name || '%')
group by ev.host
order by events desc;

-- ── 11. 社團註冊時間分布(每週) ──────────────────────────
select date_trunc('week', created_at)::date as week, count(*)
from clubs
group by 1
order by 1;

-- ── 12. 代打貼文成效 ──────────────────────────────────
select
  count(*)                                     as subs_total,
  count(*) filter (where filled)               as filled_total,
  count(*) filter (where expires_at < now()
                     and not filled)           as expired_unfilled,
  round(100.0 * count(*) filter (where filled)
        / nullif(count(*), 0), 1)              as pct_filled
from subs;

-- ── 13. 建檔後有沒有回來編輯過 【需要 migration】──────────
-- 跟第 2 段互補:那邊問「有沒有回來登入」,這邊問「有沒有回來維護內容」。
-- ⚠️ 已實測確認 claim_item() 認領舊資料時的 update 也會觸發 trigger,
--    被記成一次編輯。認領是一次性綁定不是內容維護,會讓這裡的比例偏高。
--    搭配第 14 段看還有多少舊資料未認領,判斷灌水程度。
select
  count(*)                                                               as clubs_total,
  count(*) filter (where updated_at > created_at + interval '10 minutes') as edited_later,
  round(100.0 * count(*) filter (where updated_at > created_at + interval '10 minutes')
        / nullif(count(*), 0), 1)                                        as pct_edited
from clubs;

-- ── 14. 還有多少舊資料沒被認領(判讀第 13 段的輔助) ──────────
-- edit_keys 每被認領一次就刪一列。數字還很大 = 認領還在發生 = 第 13 段會持續被灌水
select item_table, count(*) as unclaimed
from edit_keys
group by item_table
order by unclaimed desc;

-- ── 15. subs 的編輯要扣掉系統寫入 【需要 migration】──────────
-- api/remind-subs.js 寄完提醒信會 update subs set reminder_sent_at,那是系統動作。
-- 扣掉「只被系統碰過」的那些,才是使用者真的回來改過的貼文。
select
  count(*)                                                                as subs_total,
  count(*) filter (where updated_at > created_at + interval '10 minutes') as touched_later,
  count(*) filter (where updated_at > created_at + interval '10 minutes'
                     and reminder_sent_at is not null
                     and updated_at = reminder_sent_at)                   as system_only,
  count(*) filter (where updated_at > created_at + interval '10 minutes'
                     and (reminder_sent_at is null
                          or updated_at <> reminder_sent_at))             as user_edited
from subs;

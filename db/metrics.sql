-- 團聚 BandLink 使用狀況查詢
-- 在 Supabase 主控台的 SQL Editor 執行,純唯讀,不會改到任何資料。
--
-- 讀之前要知道的兩個限制:
--
-- 1. events 和 clubs 之間沒有外鍵。events.host(主辦單位)是使用者自己打的自由文字,
--    表單範例就是「薇閣 × 明德」這種一場兩社團的寫法。所以「哪個社團辦過活動」只能用
--    名字去字串裡比對,會低估(社團全名與活動簡稱對不上)也會誤判(短名字誤中)。
--    凡是標著【估計】的段落,數字都是參考值不是事實,看之前先跑 2b 確認 host 長相。
--
-- 2. 標著【需要 001 migration】的段落,要先執行 db/migrations/001_add_updated_at.sql
--    才有資料可查,而且只涵蓋 migration 執行之後的編輯行為。

-- ── 1. 基本量體 ──────────────────────────────────────────
select
  (select count(*) from clubs)       as clubs_total,
  (select count(*) from venues)      as venues_total,
  (select count(*) from events)      as events_total,
  (select count(*) from subs)        as subs_total,
  (select count(*) from photography) as photography_total;

-- ── 2. 有辦過活動的社團比例 【估計】────────────────────────
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

-- ── 2b. 對照組:host 到底長什麼樣,決定上面那個數字可不可信 ──
select host, count(*) as events
from events
group by host
order by events desc;

-- ── 3. 社團註冊時間分布(每週) ────────────────────────────
select date_trunc('week', created_at)::date as week, count(*)
from clubs
group by 1
order by 1;

-- ── 4. 活躍度分層 【估計】──────────────────────────────
-- last_touch =「建檔時間」與「最新一場疑似由它主辦的活動建檔時間」的較晚者
select
  count(*) filter (where last_touch >  now() - interval '7 days')  as active_7d,
  count(*) filter (where last_touch >  now() - interval '30 days') as active_30d,
  count(*) filter (where last_touch <= now() - interval '30 days') as dormant
from (
  select c.id,
         greatest(c.created_at, coalesce(max(ev.created_at), c.created_at)) as last_touch
  from clubs c
  left join events ev on ev.host ilike '%' || c.name || '%'
  group by c.id, c.created_at
) t;

-- ── 4b. 建檔後有沒有回來編輯過 【需要 001 migration】──────
-- 這才是原本想問的「留存」:填完就走 vs 真的當工具在用
select
  count(*)                                                               as clubs_total,
  count(*) filter (where updated_at > created_at + interval '10 minutes') as edited_later,
  round(100.0 * count(*) filter (where updated_at > created_at + interval '10 minutes')
        / nullif(count(*), 0), 1)                                        as pct_edited
from clubs;

-- ── 5. 已註冊社團完整名單 ──────────────────────────────
select name, created_at::date
from clubs
order by created_at;

-- ── 6. 活動實際狀態 ────────────────────────────────────
-- 沒有 start_time,日期是 date 欄位;time 是自由文字所以不參與比較
select
  count(*) filter (where date >= current_date)            as upcoming,
  count(*) filter (where coalesce(trim(venue), '') <> '') as with_venue,
  count(*) filter (where state = '開放報名')               as open_for_signup,
  count(*)                                                as total
from events;

-- ── 6b. 活動填的場地有多少對得上 venues 表 【估計】────────
-- 衡量「場地」這個功能有沒有真的被用到,還是大家自己打
select
  count(*) filter (where exists (
    select 1 from venues v where ev.venue ilike '%' || v.name || '%'
  ))       as venue_matched,
  count(*) as total
from events ev;

-- ── 7. 代打貼文成效 ────────────────────────────────────
select
  count(*)                                     as subs_total,
  count(*) filter (where filled)               as filled_total,
  count(*) filter (where expires_at < now()
                     and not filled)           as expired_unfilled,
  round(100.0 * count(*) filter (where filled)
        / nullif(count(*), 0), 1)              as pct_filled
from subs;

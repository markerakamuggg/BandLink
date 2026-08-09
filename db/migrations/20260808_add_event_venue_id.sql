-- ============================================================
-- BandLink migration: 20260808_add_event_venue_id.sql
-- 目的:讓活動與場地真正連在一起。
--
-- 背景:events.venue 是使用者自由打字的文字欄,同一個場地有多種寫法
--       (「公館PIPE」「公館pipe」「公館Pipe Live Music」都是 PIPE),
--       正式環境 10 筆活動只有 2 筆對得上 venues 表。任何「這個場地
--       哪天有演出」的功能都需要一個確定的關聯,而不是猜字串。
--
-- 安全性:可重複執行。只新增欄位與回填,不刪除任何資料。
--         venue(文字)欄位保留不動——使用者填的原始文字仍有價值,
--         而且不在場地表裡的場地(例如凝聚力音樂娛樂)只能靠它。
-- ============================================================


-- ------------------------------------------------------------
-- 1. 加上關聯欄位
--    on delete set null:萬一場地從名錄移除,活動不會跟著消失,
--    只是退回「只有文字沒有關聯」的狀態。
-- ------------------------------------------------------------
alter table public.events
  add column if not exists venue_id uuid references public.venues(id) on delete set null;

create index if not exists events_venue_id_idx on public.events (venue_id);


-- ------------------------------------------------------------
-- 2. 回填舊資料
--    以「使用者實際填過的寫法 → 場地表名稱」的對照表回填。
--    對照是人工判讀的結果,不是模糊比對——機器對不上的
--    「公館pipe」「北流LiveHouseD」人看得懂。
--
--    只填 venue_id 仍為 null 的資料,已經有關聯的不覆蓋。
-- ------------------------------------------------------------
with alias(written, venue_name) as (values
  -- PIPE 的四種寫法
  ('公館PIPE',                 'PIPE Live Music'),
  ('公館pipe',                 'PIPE Live Music'),
  ('公館Pipe Live Music',      'PIPE Live Music'),
  ('PIPE',                     'PIPE Live Music'),
  -- 北流
  ('北流LiveHouseD',           '北流 Live House D'),
  ('北流live house D',         '北流 Live House D'),
  ('北流Live House D',         '北流 Live House D'),
  -- The Wall
  ('THE WALL LIVE HOUSE',      'The Wall 公館'),
  ('The Wall',                 'The Wall 公館'),
  -- 河岸留言西門紅樓
  ('河岸留言西門紅樓展演館',    '河岸留言西門紅樓展演館'),
  ('西門河岸留言',              '河岸留言西門紅樓展演館'),
  -- 凝聚力(名錄後補,先跑 seed-venues.sql 才對得上)
  ('凝聚力音樂娛樂',            '凝聚力音樂娛樂 Cohesion'),
  ('凝聚力',                    '凝聚力音樂娛樂 Cohesion'),
  -- 角落文創
  ('角落文創',                  '角落文創展演空間 Corner House'),
  ('角落文創展演空間',          '角落文創展演空間 Corner House'),
  ('Corner House',              '角落文創展演空間 Corner House'),
  ('角落',                      '角落文創展演空間 Corner House'),
  -- 其餘場地的標準寫法(未來使用者若照抄名錄名稱也能對上)
  ('河岸留言公館本店',          '河岸留言公館本店'),
  ('Revolver',                 'Revolver'),
  ('Legacy Taipei',            'Legacy Taipei'),
  ('狀態音樂 State Music',      '狀態音樂 State Music'),
  ('Zepp New Taipei',          'Zepp New Taipei')
)
update public.events e
   set venue_id = v.id
  from alias a
  join public.venues v on v.name = a.venue_name
 where e.venue_id is null
   and lower(trim(e.venue)) = lower(trim(a.written));


-- ------------------------------------------------------------
-- 3. 驗證:跑完看這兩段
-- ------------------------------------------------------------

-- 已關聯 / 未關聯的比例
select
  count(*)                                as 活動總數,
  count(*) filter (where venue_id is not null) as 已關聯場地,
  count(*) filter (where venue_id is null)     as 仍是純文字
from public.events;

-- 還沒對上的原始寫法——這些要嘛是場地表沒有的場地,
-- 要嘛是還沒收進上面對照表的新寫法
select e.venue as 未對上的寫法, count(*) as 筆數
from public.events e
where e.venue_id is null
group by e.venue
order by 筆數 desc, e.venue;


-- ============================================================
-- 備註
-- ------------------------------------------------------------
-- 這份 migration 之後,「辦演出」表單改為從名錄選場地(見 src/App.jsx
-- 的 EventForm),新建的活動會直接帶 venue_id,不再需要回填。
-- 使用者仍可選「其他」自行輸入,那種情況 venue_id 為 null、
-- venue 保留文字,場地檔期表會把它歸在「其他場地」。
-- ============================================================

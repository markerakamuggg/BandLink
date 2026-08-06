-- ============================================================
-- BandLink migration: 20260804_add_updated_at.sql
-- 目的:為 clubs / venues / events / subs 加上 updated_at 欄位,
--       並掛上 trigger 讓每次 UPDATE 自動記錄修改時間。
--
-- 執行方式:
--   Supabase 網頁後台 → SQL Editor → 貼上整份 → Run
--
-- 安全性:此檔可重複執行,不會破壞既有資料。
-- 限制:只對執行「之後」的編輯行為有效,過去的改動補不回來。
-- ============================================================


-- ------------------------------------------------------------
-- 1. 共用 trigger function
-- ------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


-- ------------------------------------------------------------
-- 2. 加欄位
--    先加成可為空 → 用 created_at 回填 → 最後才設 default。
--    順序很重要:如果一開始就帶 default now(),Postgres 會把所有
--    既有資料的 updated_at 直接填成執行當下,舊資料會全部看起來
--    像剛剛才被編輯過,回填就來不及了。
--
--    四張表都有 created_at,所以回填語句可直接使用。
-- ------------------------------------------------------------
alter table public.clubs  add column if not exists updated_at timestamptz;
alter table public.venues add column if not exists updated_at timestamptz;
alter table public.events add column if not exists updated_at timestamptz;
alter table public.subs   add column if not exists updated_at timestamptz;

update public.clubs  set updated_at = created_at where updated_at is null;
update public.venues set updated_at = created_at where updated_at is null;
update public.events set updated_at = created_at where updated_at is null;
update public.subs   set updated_at = created_at where updated_at is null;

alter table public.clubs  alter column updated_at set default now();
alter table public.venues alter column updated_at set default now();
alter table public.events alter column updated_at set default now();
alter table public.subs   alter column updated_at set default now();


-- ------------------------------------------------------------
-- 3. 掛 trigger(先 drop 再 create,重跑不會出錯)
-- ------------------------------------------------------------
drop trigger if exists set_updated_at on public.clubs;
create trigger set_updated_at
  before update on public.clubs
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.venues;
create trigger set_updated_at
  before update on public.venues
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.events;
create trigger set_updated_at
  before update on public.events
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.subs;
create trigger set_updated_at
  before update on public.subs
  for each row execute function public.set_updated_at();


-- ============================================================
-- 驗證:跑完上面之後,執行以下兩段確認結果
-- ============================================================

-- 應該看到 clubs / events / subs / venues 四筆
select table_name, column_name
from information_schema.columns
where table_schema = 'public' and column_name = 'updated_at'
order by table_name;

-- 應該看到四個名為 set_updated_at 的 trigger
select event_object_table, trigger_name, action_timing, event_manipulation
from information_schema.triggers
where trigger_schema = 'public' and trigger_name = 'set_updated_at'
order by event_object_table;


-- ============================================================
-- 兩個會影響數字判讀的提醒
-- ------------------------------------------------------------
-- 1. Trigger 只認得經過資料庫的 UPDATE。已檢查 src/App.jsx:254-260,
--    編輯走的是 supabase.from(table).update(),是真正的 UPDATE,
--    不是 DELETE 再 INSERT,所以 trigger 會正常觸發。
--
-- 2. claim_item() 認領舊內容時會執行 update ... set user_id = auth.uid(),
--    這會觸發 trigger,把那筆資料記成「編輯過」。認領是一次性的綁定動作,
--    不是內容維護,所以若認領還在發生,pct_edited 會被灌水。
--    可用 edit_keys 的剩餘筆數判斷還有多少舊資料未認領。
--
-- 3. api/remind-subs.js 寄出提醒信後會 update subs set reminder_sent_at,
--    那是系統寫入不是使用者編輯,同樣會觸發 trigger。看 subs 的編輯率時
--    要把這件事算進去(或改看 updated_at 與 reminder_sent_at 不相等的筆數)。
-- ============================================================

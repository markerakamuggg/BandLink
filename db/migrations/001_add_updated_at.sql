-- 加上「最後修改時間」欄位,讓「有多少社團建檔後還會回來編輯」這個問題問得出來。
--
-- 為什麼需要:目前所有表只有 created_at(建立時間),沒有任何地方記錄「後來被改過」。
-- 所以「登記完就沒再動」和「持續在維護」這兩種社團,在資料上長得一模一樣。
--
-- ⚠️ 重要:這只對執行之後的編輯行為有效。過去誰改過什麼沒有留下痕跡,補不回來。
--    現有資料的 updated_at 會被填成跟 created_at 一樣,代表「尚未觀測到編輯」。
--
-- 執行方式:Supabase 主控台 → SQL Editor → 整段貼上執行。
-- 安全性:只新增欄位與觸發器,不會刪除或覆寫任何既有資料。可重複執行。

alter table clubs  add column if not exists updated_at timestamptz default now();
alter table events add column if not exists updated_at timestamptz default now();
alter table subs   add column if not exists updated_at timestamptz default now();

-- 既有資料先對齊 created_at,避免舊資料看起來像「剛剛才改過」
update clubs  set updated_at = created_at where updated_at is null or updated_at > created_at;
update events set updated_at = created_at where updated_at is null or updated_at > created_at;
update subs   set updated_at = created_at where updated_at is null or updated_at > created_at;

-- 每次 update 時自動把 updated_at 設為當下,不需要 App 端配合改任何程式碼
create or replace function touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists clubs_touch_updated_at on clubs;
create trigger clubs_touch_updated_at
  before update on clubs
  for each row execute function touch_updated_at();

drop trigger if exists events_touch_updated_at on events;
create trigger events_touch_updated_at
  before update on events
  for each row execute function touch_updated_at();

drop trigger if exists subs_touch_updated_at on subs;
create trigger subs_touch_updated_at
  before update on subs
  for each row execute function touch_updated_at();

-- 跑完之後,db/metrics.sql 裡標著「需要 001 migration」的那幾段就能用了。

-- 團聚 BandLink 資料庫結構
-- ⚠️ 這份檔案是從正式環境(Supabase 專案 fvqnhmyimanvupqcsjjj)直接讀回來的現況紀錄,
--    不是要拿去重新執行的建置腳本。這個專案已經上線、已有真實社團/活動資料,
--    整段重跑會建表失敗(表已存在)或砍掉正式資料——不要這樣做。
--    用途:留底現況,以及之後要建全新環境(例如測試專案)時參考。

create table clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  area text not null,
  genre text default '',
  members int default 0,
  bands int default 0,
  intro text default '',
  contact text not null,
  created_at timestamptz default now(),
  user_id uuid default auth.uid()
);

create table posts (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('徵團','自薦')),
  club text not null,
  title text not null,
  body text not null,
  contact text not null,
  created_at timestamptz default now(),
  user_id uuid default auth.uid()
);

create table events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  host text not null,
  date date not null,
  time text default '',
  venue text not null,
  state text default '開放報名',
  descr text default '',
  created_at timestamptz default now(),
  contact text default '',
  user_id uuid default auth.uid()
);

-- 場地:只能由管理者用 Supabase Table Editor 維護,App 內沒有新增/編輯介面
create table venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  area text not null,
  cap int default 0,
  price text default '',
  note text default '',
  tags text default '',
  created_at timestamptz default now()
);

create table venue_apps (
  id uuid primary key default gen_random_uuid(),
  venue text not null,
  club text not null,
  event_date date not null,
  size text default '',
  contact text not null,
  note text default '',
  state text default '審核中',
  created_at timestamptz default now()
);

-- 編輯碼認領對照表:通用於 clubs/posts/events,一組碼對應一筆「登入功能上線前」發布的舊資料
-- 沒有任何 RLS policy → 一律拒絕直接存取,只能透過下面的 claim_item() 走
create table edit_keys (
  item_table text not null,
  item_id uuid not null,
  code text not null,
  primary key (item_table, item_id)
);

alter table clubs enable row level security;
alter table posts enable row level security;
alter table events enable row level security;
alter table venues enable row level security;
alter table venue_apps enable row level security;
alter table edit_keys enable row level security;

create policy "clubs 公開讀取" on clubs for select using (true);
create policy "clubs 登入新增" on clubs for insert with check (auth.uid() = user_id);
create policy "clubs 本人修改" on clubs for update using (auth.uid() = user_id);
create policy "clubs 本人刪除" on clubs for delete using (auth.uid() = user_id);

create policy "posts 公開讀取" on posts for select using (true);
create policy "posts 登入新增" on posts for insert with check (auth.uid() = user_id);
create policy "posts 本人修改" on posts for update using (auth.uid() = user_id);
create policy "posts 本人刪除" on posts for delete using (auth.uid() = user_id);

create policy "events 公開讀取" on events for select using (true);
create policy "events 登入新增" on events for insert with check (auth.uid() = user_id);
create policy "events 本人修改" on events for update using (auth.uid() = user_id);
create policy "events 本人刪除" on events for delete using (auth.uid() = user_id);

create policy "venues 公開讀取" on venues for select using (true);

create policy "venue_apps 公開讀取" on venue_apps for select using (true);
create policy "venue_apps 公開新增" on venue_apps for insert with check (true);

-- 產生隨機編輯碼(格式 XXXX-XXXX)
create or replace function _gen_code()
returns text
language sql
as $$ select upper(substr(md5(random()::text || clock_timestamp()::text), 1, 4)
  || '-' || substr(md5(random()::text || clock_timestamp()::text), 1, 4)) $$;

-- 認領舊內容:輸入編輯碼,把對應的 clubs/posts/events 資料 user_id 綁定到目前登入帳號,用過即刪除該碼
create or replace function claim_item(p_code text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare r record;
begin
  if auth.uid() is null then
    return null;
  end if;
  select item_table, item_id into r from edit_keys where code = upper(trim(p_code)) limit 1;
  if not found then
    return null;
  end if;
  if r.item_table = 'posts' then
    update posts set user_id = auth.uid() where id = r.item_id;
  elsif r.item_table = 'events' then
    update events set user_id = auth.uid() where id = r.item_id;
  elsif r.item_table = 'clubs' then
    update clubs set user_id = auth.uid() where id = r.item_id;
  end if;
  delete from edit_keys where item_table = r.item_table and item_id = r.item_id;
  return jsonb_build_object('item_table', r.item_table, 'item_id', r.item_id);
end
$function$;

grant execute on function claim_item(text) to authenticated;

-- 專案層級維運機制(非本 app 特有邏輯):新建的表自動打開 RLS,避免忘記開
create or replace function rls_auto_enable()
returns event_trigger
language plpgsql
security definer
set search_path to 'pg_catalog'
as $function$
declare
  cmd record;
begin
  for cmd in
    select * from pg_event_trigger_ddl_commands()
    where command_tag in ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      and object_type in ('table','partitioned table')
  loop
    if cmd.schema_name = 'public' then
      execute format('alter table if exists %s enable row level security', cmd.object_identity);
    end if;
  end loop;
end;
$function$;

create event trigger ensure_rls on ddl_command_end
  when tag in ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
  execute function rls_auto_enable();

-- 示範資料僅供全新環境參考,正式環境已有真實資料,不要重複執行以下 insert
-- insert into clubs (name, area, genre, members, bands, intro, contact) values (...);
-- insert into events (title, host, date, time, venue, state, descr, contact) values (...);
-- insert into venues (name, area, cap, price, note, tags) values (...);

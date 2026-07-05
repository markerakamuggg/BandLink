-- 團聚 BandLink 資料庫結構
-- 使用方式:到 Supabase 專案 → SQL Editor → 貼上全部 → Run

-- 社團名錄
create table clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  area text not null,
  genre text default '',
  members int default 0,
  bands int default 0,
  intro text default '',
  contact text not null,
  created_at timestamptz default now()
);

-- 媒合貼文(徵團 / 自薦)
create table posts (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('徵團','自薦')),
  club text not null,
  title text not null,
  body text not null,
  contact text not null,
  created_at timestamptz default now()
);

-- 活動(演出)
create table events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  host text not null,
  date date not null,
  time text default '',
  venue text not null,
  state text default '開放報名',
  descr text default '',
  created_at timestamptz default now()
);

-- 場地申請
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

-- 安全政策:任何人可讀、可新增,但不能修改或刪除別人的資料
alter table clubs enable row level security;
alter table posts enable row level security;
alter table events enable row level security;
alter table venue_apps enable row level security;

create policy "clubs 公開讀取" on clubs for select using (true);
create policy "clubs 公開新增" on clubs for insert with check (true);
create policy "posts 公開讀取" on posts for select using (true);
create policy "posts 公開新增" on posts for insert with check (true);
create policy "events 公開讀取" on events for select using (true);
create policy "events 公開新增" on events for insert with check (true);
create policy "venue_apps 公開讀取" on venue_apps for select using (true);
create policy "venue_apps 公開新增" on venue_apps for insert with check (true);

-- 示範資料(可自行刪改)
insert into clubs (name, area, genre, members, bands, intro, contact) values
('薇閣高中 熱音社', '台北市.北投', 'Rock / J-Rock', 32, 6, '以翻唱 ONE OK ROCK、傷心欲絕為主,近年開始嘗試原創。每年寒暑各辦一場成發。', 'IG @wg_rockclub'),
('明德高中 熱音社', '台北市.北投', 'Pop Punk / Rock', 24, 4, '社風自由,鼓手很多。常與鄰近學校聯合舉辦期末聯展。', 'IG @mdsh_band'),
('板橋高中 熱音社', '新北市.板橋', 'Indie / Post-Rock', 40, 8, '新北老牌熱音社,擁有完整練團室設備,歡迎跨校交流練團。', 'IG @pcsh_music');

insert into events (title, host, date, time, venue, state, descr) values
('薇獨明天颳颱楓 聯合演出', '薇閣 × 明德 × TCS', '2026-08-15', '18:30', '板橋 Live House', '售票中', '三校聯合暑期聯展,共 9 團演出。');

insert into posts (kind, club, title, body, contact) values
('徵團', '板橋高中 熱音社', '期末聯展徵 2 組外校樂團', '9 月校內聯展尚有 2 個表演時段(各 25 分鐘),曲風不限,提供基本 backline。', 'IG @pcsh_music');

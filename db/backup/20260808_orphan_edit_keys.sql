-- 還原檔:2026-08-08 清理的孤兒認領碼(16 筆)
--
-- 這些 edit_keys 的 item_id 指向已經不存在的 clubs / events,
-- 對應內容早就被刪除,碼發出去也認領不到任何東西,
-- 但會讓「未認領筆數」這個指標虛高(37 → 實際只有 21 筆有效)。
--
-- 清理前已確認:
--   13 筆 item_table='clubs'  → clubs  查無此 id
--    3 筆 item_table='events' → events 查無此 id
--
-- 若日後發現誤刪(例如該內容其實是被還原回來的),執行本檔即可還原。
-- 注意:還原後這些碼仍然指向不存在的資料,除非對應的 clubs/events
-- 也一併還原,否則還原它們沒有實質意義。

insert into edit_keys (item_table, item_id, code) values
  ('clubs',  '712074d6-fd06-4171-8bc9-40932ef6e691', '085F-BA4C'),
  ('clubs',  'b4662867-89f4-457b-ab29-81b9ced0403d', '0EC9-2D42'),
  ('clubs',  '846efc20-0ecc-4170-8163-65ac2b0d70fe', '21B5-C206'),
  ('clubs',  '60821ffc-020b-42d4-833c-5cfa3b46ec65', '5319-7163'),
  ('clubs',  'd77bb9a7-5821-4cf1-a21e-204148e457cd', '55F1-8820'),
  ('clubs',  'f7213ddb-a620-4ccf-a2da-d9c9fe5ebee7', '632F-E31F'),
  ('clubs',  '672bbc01-a585-4291-9444-e82580c1af46', '82AC-6D10'),
  ('clubs',  '5a928ea3-2ee3-4ea2-afde-d5e4664f112c', '87F7-C04F'),
  ('clubs',  '03c9b729-d359-4094-beaf-c2c209a3d9b0', 'A420-0119'),
  ('clubs',  '6e472fae-9f38-4f70-9a75-d4adb906efd3', 'C3B9-7569'),
  ('clubs',  '9cec81c9-4083-4249-a645-3c500d9fb7eb', 'DA90-A5D5'),
  ('clubs',  'e1387065-afa7-4a02-abff-99ce50829444', 'DF74-7BC1'),
  ('clubs',  'c54e7d29-aa6d-4620-a39b-ea00369bf999', 'F5F5-DAEC'),
  ('events', 'fa77fa37-7fe0-4639-b06e-fd440659fc14', '2ED4-728B'),
  ('events', 'ae3139b2-af28-4cfc-a848-4b7aca3a7962', '43FE-9D47'),
  ('events', 'd53133de-7f63-4d70-92bd-4ebb2a854d6b', 'E518-C6C0')
on conflict (item_table, item_id) do nothing;

-- 場地表初始資料:雙北高中熱音成發常用的展演空間。
-- 在 Supabase SQL Editor 貼上整份執行。
--
-- 【重複執行的行為】
--   同名場地會被「更新」為本檔的最新內容,不是跳過也不是重複新增。
--   所以改了聯絡方式或備註,重跑一次就會生效。
--
-- 【會刪掉什麼】
--   只刪本檔曾經管理過、但現已移出的場地(三創 / SUB / 月見ル,
--   已移至 seed-venues-pending.sql 等查證)。
--   你自己在 Table Editor 手動新增的場地不會被動到——刪除是按名單點名,
--   不是整表清空。
--
-- ⚠️ 資料整理自公開資訊(官網/媒體/社群整理文)與模型記憶,容量為約略值,
--    包場費用變動快所以一律寫「請洽場地」。執行前自己過目一遍,
--    聯絡方式與費用請以各場地官方公告為準。
--
-- 欄位對照:name(名稱) area(行政區) cap(容納人數,約) price(費用) note(備註) contact(聯絡)

-- 1. 移除已從本清單移出的場地(僅點名這三筆,不影響其他資料)
delete from venues
where name in ('三創 Clapper Studio', 'SUB Livehouse', '月見ル君想フ 台北');

-- 2. 寫入/更新場地
with seed(name, area, cap, price, note, contact) as (values
  ('河岸留言西門紅樓展演館', '台北・萬華(西門紅樓)', 350, '包場費請洽場地',
   '高中成發最熱門的場地之一,週末檔期常提早數月被訂走,想辦成發先問這裡。官網 riverside.com.tw',
   'riverside.com.tw/livehouse'),
  ('河岸留言公館本店', '台北・中正(公館)', 80, '包場費請洽場地',
   '小型咖啡展演空間,適合小型售票場、不插電或個人專場。官網 riverside.com.tw',
   'riverside.com.tw'),
  ('The Wall 公館', '台北・文山(公館)', 600, '包場費請洽場地',
   '獨立音樂指標場地,適合較大型成發或多校聯合。售票資訊多在 KKTIX。',
   'thewalllivehouse.kktix.cc'),
  ('Revolver', '台北・中正(中正紀念堂旁)', 120, '包場費請洽場地',
   '酒吧型小場地,學生樂團常演。空間較小、屬酒吧業態,時段與年齡規定先確認。',
   '@revolver.taipei'),
  ('PIPE Live Music', '台北・中正(公館自來水園區旁)', 200, '包場費請洽場地',
   '中型 live house,樂團場地,交通方便。',
   '@pipelivemusic'),
  ('Legacy Taipei', '台北・中正(華山1914文創園區)', 1200, '包場費請洽場地',
   '大型場館,多校聯合成發等級,費用高、檔期競爭激烈。',
   'legacy.com.tw'),
  ('角落文創展演空間 Corner House', '台北・南港(忠孝東路六段21號1樓)', 500, '包場費請洽場地',
   '站席約 500、座席約 250。捷運後山埤站 4 號出口,遠雄金融廣場玉成街口。場地規格接近正式演唱會等級,適合多校聯合成發或規模較大的獨立成發。電話 02-2653-0788,售票多在 KKTIX。',
   'corner-house.com.tw'),
  ('凝聚力音樂娛樂 Cohesion', '台北・松山(八德路三段106巷1號 B1)', 120, '場租請洽場地',
   '小巨蛋捷運站步行約 7 分鐘。2015 年成立、2018 年遷至現址,以展演空間、影音製作、人才培育為主。有社團在這裡辦過成發,是團聚上實際被使用過的場地。電話 02-2570-0025,另有 LINE 官方帳號 @710zopjy。',
   '@chmetw'),
  ('狀態音樂 State Music', '新北・板橋(中山路二段101號 B1)', 0, '場租請洽場地',
   '板橋的音樂綜合基地,一個地方同時有練團室(二四練團室)、展演空間(FuzzArtSpace)與彩排室,另有樂器販售、音響工程與錄音。對新北的社團來說是少見的在地選擇——平常練團、成發演出可以在同一個場地解決,不用每次都跨區到台北。營業時間週一至五 14:00-23:00、週六日 12:00-23:00,可刷卡與 LINE Pay。另有 LINE 官方帳號可洽詢。',
   '@state_music'),
  ('北流 Live House D', '台北・南港(臺北流行音樂中心產業區)', 200, '包場費請洽場地',
   '北流自營的 200 人展演空間,設備完善、有正式的官方租用規章,公家場地流程正規,適合學生社團申請。產業區另有 200/800/1600 人等多間 Live House。詳見官網租用資訊。',
   'tmc.taipei'),
  ('Zepp New Taipei', '新北・新莊(宏匯廣場)', 2000, '包場費請洽場地',
   '演唱會等級大場館,一般成發用不到,超大型聯合活動才需要。新北市內中小型 live house 稀少,多數社團成發仍跨區到台北市場地。',
   'zepp.tw')
),
updated as (
  update venues v
     set area = s.area, cap = s.cap, price = s.price, note = s.note, contact = s.contact
    from seed s
   where v.name = s.name
  returning v.name
)
insert into venues (name, area, cap, price, note, contact)
select s.name, s.area, s.cap, s.price, s.note, s.contact
from seed s
where not exists (select 1 from venues x where x.name = s.name);

-- 3. 跑完看一眼結果(應為 11 筆,狀態音樂的 cap 為 0 代表容量未知)
select name, area, cap, contact from venues order by area, name;

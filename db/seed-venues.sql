-- 場地表初始資料:雙北高中熱音成發常用的展演空間。
-- 在 Supabase SQL Editor 貼上整份執行。可重複執行,同名場地不會重複塞入。
--
-- ⚠️ 資料整理自公開資訊(官網/媒體/社群整理文)與模型記憶,容量為約略值,
--    包場費用變動快所以一律寫「請洽場地」。執行前自己過目一遍,
--    聯絡方式與費用請以各場地官方公告為準。
--
-- 欄位對照:name(名稱) area(行政區) cap(容納人數,約) price(費用) note(備註) contact(聯絡)

insert into venues (name, area, cap, price, note, contact)
select v.* from (values
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
   'IG 搜尋 revolver.taipei'),
  ('PIPE Live Music', '台北・中正(公館自來水園區旁)', 200, '包場費請洽場地',
   '中型 live house,樂團場地,交通方便。',
   'IG 搜尋 pipelivemusic'),
  ('三創 Clapper Studio', '台北・中正(三創生活園區 5F)', 700, '包場費請洽場地',
   '站席約 700、座席約 400。設備新、場地正式,費用相對高,適合預算充足的大型成發。',
   '三創官網或 IG 搜尋 clapperstudio'),
  ('Legacy Taipei', '台北・中正(華山1914文創園區)', 1200, '包場費請洽場地',
   '大型場館,多校聯合成發等級,費用高、檔期競爭激烈。',
   'legacy.com.tw'),
  ('SUB Livehouse', '台北・萬華(西門一帶)', 800, '包場費請洽場地',
   '較新的中大型場地。確切位置與包場方式請以官方公告為準。',
   'IG 搜尋 sub_livehouse'),
  ('月見ル君想フ 台北', '台北・大安(師大公館一帶)', 100, '包場費請洽場地',
   '日系 live house,小型精緻場。確切地址請以官方公告為準。',
   'IG 搜尋 moonromantic_taipei'),
  ('北流 Live House D', '台北・南港(臺北流行音樂中心產業區)', 200, '包場費請洽場地',
   '北流自營的 200 人展演空間,設備完善、有正式的官方租用規章,公家場地流程正規,適合學生社團申請。產業區另有 200/800/1600 人等多間 Live House。詳見官網租用資訊。',
   'tmc.taipei'),
  ('Zepp New Taipei', '新北・新莊(宏匯廣場)', 2000, '包場費請洽場地',
   '演唱會等級大場館,一般成發用不到,超大型聯合活動才需要。新北市內中小型 live house 稀少,多數社團成發仍跨區到台北市場地。',
   'zepp.tw')
) as v(name, area, cap, price, note, contact)
where not exists (select 1 from venues x where x.name = v.name);

-- 跑完看一眼塞進去幾筆
select name, area, cap from venues order by created_at desc, name;

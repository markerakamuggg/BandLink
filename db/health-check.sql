-- 資料健康檢查:找出會讓統計數字失真的髒資料。
-- 純唯讀,不會改到任何資料。結果只有一格,點開複製即可。
--
-- 為什麼需要這個:
--   2026-08-08 發現 edit_keys 有 16 筆認領碼指向已被刪除的 clubs/events。
--   這些碼永遠認領不到東西,卻讓「未認領筆數」從實際的 21 虛報成 37,
--   差了將近一倍。單看某張表的 count(*) 看不出這種問題,要交叉比對才會現形。
--
-- 建議每次看 snapshot.sql 之前先跑這個,確認數字是乾淨的。

with
orphan_keys as (
  select k.item_table, k.code
  from edit_keys k
  where (k.item_table = 'clubs'  and not exists (select 1 from clubs  c where c.id = k.item_id))
     or (k.item_table = 'events' and not exists (select 1 from events e where e.id = k.item_id))
     or k.item_table not in ('clubs','events')
),
claimed_but_keyed as (          -- 已綁帳號卻還留著認領碼(claim_item 應該會刪掉)
  select c.name from edit_keys k join clubs c on c.id = k.item_id
  where k.item_table = 'clubs' and c.user_id is not null
),
no_owner_no_key as (            -- 無主又沒有認領碼:沒有任何辦法可以認領回去
  select c.name from clubs c
  where c.user_id is null
    and not exists (select 1 from edit_keys k where k.item_table='clubs' and k.item_id = c.id)
),
dup_clubs as (                  -- 同名社團,可能重複登錄
  select name, count(*) as n from clubs group by name having count(*) > 1
),
no_contact as (                 -- 沒留聯絡方式:DM 名單發不出去
  select name from clubs where coalesce(trim(contact), '') = ''
)
select
  E'=== BandLink 資料健康檢查 ===\n' || now()::timestamp(0)::text || E'\n\n'
  || '[孤兒認領碼] ' ||
     case when (select count(*) from orphan_keys) = 0 then E'無\n'
          else (select count(*) from orphan_keys)::text || E' 筆,指向已刪除的資料,會讓未認領數虛高:\n'
               || (select string_agg('  ' || item_table || ' / ' || code, E'\n' order by code) from orphan_keys) || E'\n'
     end
  || '[已綁帳號卻留著碼] ' ||
     case when (select count(*) from claimed_but_keyed) = 0 then E'無\n'
          else (select count(*) from claimed_but_keyed)::text || E' 筆(碼應在認領時刪除,留著代表有異常):\n'
               || (select string_agg('  ' || name, E'\n' order by name) from claimed_but_keyed) || E'\n'
     end
  || '[無主且無認領碼] ' ||
     case when (select count(*) from no_owner_no_key) = 0 then E'無\n'
          else (select count(*) from no_owner_no_key)::text || E' 筆(沒有任何方式可認領回去,需手動處理):\n'
               || (select string_agg('  ' || name, E'\n' order by name) from no_owner_no_key) || E'\n'
     end
  || '[同名社團] ' ||
     case when (select count(*) from dup_clubs) = 0 then E'無\n'
          else (select string_agg('  ' || name || ' ×' || n, E'\n' order by name) from dup_clubs) || E'\n'
     end
  || '[未留聯絡方式] ' ||
     case when (select count(*) from no_contact) = 0 then E'無\n'
          else (select count(*) from no_contact)::text || E' 筆(DM 名單會缺這幾筆):\n'
               || (select string_agg('  ' || name, E'\n' order by name) from no_contact) || E'\n'
     end
  || E'\n[認領進度] 社團 '
  || (select count(*) from clubs)::text || ' 個,已綁帳號 '
  || (select count(*) from clubs where user_id is not null)::text || ' 個,待認領 '
  || (select count(*) from edit_keys k join clubs c on c.id=k.item_id
      where k.item_table='clubs' and c.user_id is null)::text || ' 個'
  as 健康檢查;

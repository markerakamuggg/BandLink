# 團聚 BandLink — 部署指南

雙北高中熱音社互聯平台。前端 React (Vite),資料庫 Supabase,託管 Vercel,全程免費方案即可。

照著以下四步做,約 30–60 分鐘可上線。

---

## 第一步:建立 Supabase 資料庫(約 10 分鐘)

1. 到 https://supabase.com 用 GitHub 或 Google 帳號註冊
2. 點 **New project**:
   - Name 隨意(例如 `bandlink`)
   - Database Password 設一組並記下來(之後幾乎用不到,但要保存)
   - Region 選 **Northeast Asia (Tokyo)**,離台灣最近
3. 等專案建立完成後,左側選單點 **SQL Editor** → **New query**
4. 打開本專案的 `supabase-schema.sql`,全部複製貼上 → 按 **Run**
   - 成功會顯示 `Success. No rows returned`,資料表和示範資料就建好了
5. 左側選單點 **Project Settings → API**,記下兩個值:
   - **Project URL**(形如 `https://xxxx.supabase.co`)
   - **anon public** key(一長串英數字)

> anon key 本來就是設計成公開在前端的,安全性由第 4 步建立的 Row Level Security 政策把關(任何人可讀可新增、不能改不能刪),所以放進前端沒有問題。

## 第二步:把程式碼放上 GitHub(約 10 分鐘)

1. 到 https://github.com 登入(你已經有帳號了)
2. 點右上 **+ → New repository**,名稱例如 `bandlink`,選 **Private** 或 Public 都可以,按 **Create repository**
3. 上傳程式碼,兩種方式擇一:
   - **網頁上傳(最簡單)**:在新 repo 頁面點 **uploading an existing file**,把本專案資料夾裡的所有檔案拖進去(**不要**拖 `node_modules` 和 `dist`,如果有的話),Commit
   - **指令上傳**(如果你電腦有裝 git):
     ```bash
     cd bandlink-app
     git init && git add . && git commit -m "init"
     git branch -M main
     git remote add origin https://github.com/你的帳號/bandlink.git
     git push -u origin main
     ```

## 第三步:部署到 Vercel(約 10 分鐘)

1. 到 https://vercel.com 用 **GitHub 帳號**登入
2. 點 **Add New → Project**,選剛剛的 `bandlink` repo → **Import**
3. Framework Preset 會自動偵測為 **Vite**,不用改
4. 展開 **Environment Variables**,加入兩個變數(值來自第一步第 5 點):
   | Name | Value |
   |---|---|
   | `VITE_SUPABASE_URL` | 你的 Project URL |
   | `VITE_SUPABASE_ANON_KEY` | 你的 anon public key |
5. 按 **Deploy**,等 1–2 分鐘
6. 完成後會拿到一個網址,形如 `https://bandlink-xxxx.vercel.app` — 這就是你的 app

## 第四步:測試與發布(約 5 分鐘)

1. 手機打開網址,確認能看到示範社團與活動
2. 發一篇媒合貼文,換另一台裝置打開,確認看得到 → 代表資料庫串接成功
3. 手機瀏覽器選單點「加入主畫面」,就會像原生 app 一樣有圖示
4. 把網址丟到各校社長群組

---

## 日常維護

- **改程式碼**:改完 push 到 GitHub,Vercel 會自動重新部署
- **看資料 / 刪不當貼文**:Supabase 後台 → **Table Editor**,直接編輯或刪除任何一列
- **本機開發**:複製 `.env.example` 為 `.env` 填入兩個值,然後 `npm install` → `npm run dev`

## 目前的取捨(之後可升級)

- **沒有登入系統**:發文靠填寫社團名稱,無法防冒名。流量大了之後可加 Supabase 的 Google OAuth 登入
- **任何人可發文、不能刪改**:防止互相亂改,但垃圾貼文需要你去 Supabase 後台手動刪
- **場地資料寫死在程式裡**(`src/App.jsx` 的 `VENUES`):要新增場地直接改那個陣列;示範用的場地價格是虛構的,請換成實際洽詢到的資訊
- **免費額度**:Supabase 免費版 500MB 資料庫 + Vercel 免費流量,以純文字貼文的量級,幾年內都用不完

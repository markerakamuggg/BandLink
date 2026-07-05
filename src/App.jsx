import React, { useState, useEffect } from "react";
import { supabase, configured } from "./supabase.js";

/* ── 團聚 BandLink ─ 雙北高中熱音社互聯平台 ── */

const C = {
  bg: "#191216", card: "#241B21", card2: "#2E2229", line: "#3A2C33",
  amber: "#FFB525", pink: "#FF4D6D", paper: "#F2EAE0", mute: "#9C8E95",
};

const VENUES = [
  { id: "v1", name: "PIPE Live Music", area: "台北市.中正", cap: 350, price: "NT$18,000 起 / 場", note: "河岸旁場館,音響完整,常接學生聯展,建議 6 週前申請。", tags: ["Live House", "含音控"] },
  { id: "v2", name: "板橋 Corner House", area: "新北市.板橋", cap: 200, price: "NT$12,000 起 / 場", note: "板橋在地 Live House,對高中社團友善,可多校分攤場租合辦。", tags: ["Live House", "學生友善"] },
  { id: "v3", name: "濕地 venue 5F", area: "台北市.中山", cap: 150, price: "NT$9,000 起 / 場", note: "小型展演空間,適合 3–4 團規模的小型聯展或發表會。", tags: ["展演空間"] },
  { id: "v4", name: "學校活動中心(跨校借用)", area: "雙北各校", cap: 400, price: "多為免費 / 行政流程", note: "透過學務處提出跨校借用公文,週期較長,建議 8 週前申請。", tags: ["校內場地", "免費"] },
];

/* ── 小元件 ── */
const Tag = ({ children, tone = "amber" }) => (
  <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1, color: tone === "amber" ? C.amber : C.pink, border: `1px solid ${tone === "amber" ? C.amber : C.pink}`, padding: "2px 8px", borderRadius: 2, whiteSpace: "nowrap" }}>{children}</span>
);

const SectionTitle = ({ zh, en }) => (
  <div style={{ margin: "22px 0 12px", display: "flex", alignItems: "baseline", gap: 10 }}>
    <h2 style={{ margin: 0, fontSize: 22, fontWeight: 900, letterSpacing: 2, color: C.paper }}>{zh}</h2>
    <span style={{ fontFamily: "monospace", fontSize: 11, letterSpacing: 2, color: C.mute }}>{en}</span>
  </div>
);

const inputStyle = { width: "100%", boxSizing: "border-box", background: C.bg, color: C.paper, border: `1px solid ${C.line}`, borderRadius: 4, padding: "10px 12px", fontSize: 15, fontFamily: "inherit", outline: "none" };

const Field = ({ label, ...props }) => (
  <label style={{ display: "block", marginBottom: 12 }}>
    <div style={{ fontSize: 12, color: C.mute, marginBottom: 4, letterSpacing: 1 }}>{label}</div>
    {props.rows ? <textarea {...props} style={inputStyle} /> : <input {...props} style={inputStyle} />}
  </label>
);

const Btn = ({ children, tone = "amber", ...props }) => (
  <button {...props} style={{ background: tone === "amber" ? C.amber : tone === "pink" ? C.pink : "transparent", color: tone === "ghost" ? C.mute : "#1A1115", border: tone === "ghost" ? `1px solid ${C.line}` : "none", fontWeight: 800, fontSize: 14, letterSpacing: 1, padding: "10px 18px", borderRadius: 4, cursor: "pointer", fontFamily: "inherit", ...(props.style || {}) }}>{children}</button>
);

const Modal = ({ title, onClose, children }) => (
  <div onClick={onClose} style={{ position: "fixed", inset: 0, background: "rgba(10,6,8,.78)", zIndex: 50, display: "flex", alignItems: "flex-end", justifyContent: "center" }}>
    <div onClick={e => e.stopPropagation()} style={{ width: "100%", maxWidth: 560, maxHeight: "86vh", overflowY: "auto", background: C.card, borderTop: `3px solid ${C.amber}`, borderRadius: "14px 14px 0 0", padding: "18px 18px 28px" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
        <h3 style={{ margin: 0, fontSize: 18, fontWeight: 900, letterSpacing: 1.5, color: C.paper }}>{title}</h3>
        <button onClick={onClose} aria-label="關閉" style={{ background: "none", border: "none", color: C.mute, fontSize: 22, cursor: "pointer" }}>×</button>
      </div>
      {children}
    </div>
  </div>
);

const fmtDate = d => (d ? String(d).slice(0, 10).replaceAll("-", "/") : "");

const TicketCard = ({ ev }) => (
  <div style={{ display: "flex", background: C.card2, borderRadius: 6, overflow: "hidden", marginBottom: 14, border: `1px solid ${C.line}` }}>
    <div style={{ flex: 1, padding: "14px 16px" }}>
      <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 6 }}>
        <Tag tone={ev.state === "售票中" ? "pink" : "amber"}>{ev.state}</Tag>
        <span style={{ fontFamily: "monospace", fontSize: 11, color: C.mute }}>{fmtDate(ev.date)}・{ev.time}</span>
      </div>
      <div style={{ fontSize: 17, fontWeight: 900, letterSpacing: 1, color: C.paper, lineHeight: 1.35 }}>{ev.title}</div>
      <div style={{ fontSize: 13, color: C.amber, margin: "4px 0 6px" }}>{ev.host}</div>
      {ev.descr && <div style={{ fontSize: 13, color: C.mute, lineHeight: 1.6 }}>{ev.descr}</div>}
      <div style={{ fontSize: 12, color: C.paper, marginTop: 8 }}>📍 {ev.venue}</div>
    </div>
    <div style={{ width: 56, borderLeft: `2px dashed ${C.line}`, display: "flex", alignItems: "center", justifyContent: "center", background: C.card }}>
      <span style={{ writingMode: "vertical-rl", fontFamily: "monospace", fontSize: 11, letterSpacing: 3, color: C.mute }}>ADMIT ONE</span>
    </div>
  </div>
);

const PostCard = ({ p }) => (
  <div style={{ background: C.card, border: `1px solid ${C.line}`, borderRadius: 6, padding: "13px 15px", marginBottom: 10 }}>
    <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 6 }}>
      <Tag tone={p.kind === "徵團" ? "pink" : "amber"}>{p.kind}</Tag>
      <span style={{ fontSize: 12, color: C.mute }}>{p.club}・{fmtDate(p.created_at)}</span>
    </div>
    <div style={{ fontWeight: 900, fontSize: 15, letterSpacing: .5, color: C.paper }}>{p.title}</div>
    <div style={{ fontSize: 13, color: C.mute, lineHeight: 1.7, margin: "5px 0 8px" }}>{p.body}</div>
    <div style={{ fontFamily: "monospace", fontSize: 12, color: C.amber }}>聯絡:{p.contact}</div>
  </div>
);

/* ── 主程式 ── */
export default function App() {
  const [tab, setTab] = useState("home");
  const [clubs, setClubs] = useState([]);
  const [posts, setPosts] = useState([]);
  const [events, setEvents] = useState([]);
  const [myApps, setMyApps] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null);
  const [toast, setToast] = useState("");

  const ping = msg => { setToast(msg); setTimeout(() => setToast(""), 2400); };

  const reload = async () => {
    if (!configured) { setLoading(false); return; }
    setLoading(true);
    try {
      const [c, p, e] = await Promise.all([
        supabase.from("clubs").select("*").order("created_at"),
        supabase.from("posts").select("*").order("created_at", { ascending: false }),
        supabase.from("events").select("*").order("date"),
      ]);
      setClubs(c.data || []); setPosts(p.data || []); setEvents(e.data || []);
      const ids = JSON.parse(localStorage.getItem("my-app-ids") || "[]");
      if (ids.length) {
        const { data } = await supabase.from("venue_apps").select("*").in("id", ids).order("created_at", { ascending: false });
        setMyApps(data || []);
      }
    } catch (err) { console.error(err); ping("讀取資料失敗,請稍後再試"); }
    setLoading(false);
  };

  useEffect(() => { reload(); }, []);

  const insert = async (table, row, okMsg, trackMine = false) => {
    try {
      const { data, error } = await supabase.from(table).insert(row).select().single();
      if (error) throw error;
      if (trackMine) {
        const ids = JSON.parse(localStorage.getItem("my-app-ids") || "[]");
        localStorage.setItem("my-app-ids", JSON.stringify([data.id, ...ids]));
      }
      setModal(null); ping(okMsg); reload();
    } catch (err) { console.error(err); ping("送出失敗,請檢查網路後再試"); }
  };

  if (!configured) return (
    <div style={{ minHeight: "100vh", background: C.bg, color: C.paper, display: "flex", alignItems: "center", justifyContent: "center", padding: 24, fontFamily: "'Noto Sans TC',sans-serif" }}>
      <div style={{ maxWidth: 420, background: C.card, border: `1px solid ${C.line}`, borderRadius: 8, padding: 24 }}>
        <h2 style={{ marginTop: 0 }}>尚未連接資料庫</h2>
        <p style={{ color: C.mute, lineHeight: 1.8, fontSize: 14 }}>請依 README 指示,在 Vercel(或本機 .env 檔)設定 VITE_SUPABASE_URL 與 VITE_SUPABASE_ANON_KEY 兩個環境變數後重新部署。</p>
      </div>
    </div>
  );

  return (
    <div style={{ minHeight: "100vh", background: C.bg, color: C.paper, fontFamily: "'Noto Sans TC','PingFang TC','Microsoft JhengHei',sans-serif", paddingBottom: 76 }}>
      <header style={{ padding: "18px 18px 0" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 10 }}>
          <h1 style={{ margin: 0, fontSize: 30, fontWeight: 900, letterSpacing: 4 }}>團<span style={{ color: C.pink }}>聚</span></h1>
          <span style={{ fontFamily: "monospace", fontSize: 11, letterSpacing: 3, color: C.amber }}>BANDLINK・雙北熱音社互聯</span>
        </div>
      </header>

      {events.length > 0 && (
        <div style={{ overflow: "hidden", borderTop: `1px solid ${C.line}`, borderBottom: `1px solid ${C.line}`, margin: "12px 0 0", background: "#120C10" }}>
          <div className="marquee" style={{ display: "inline-block", whiteSpace: "nowrap", padding: "6px 0", fontFamily: "monospace", fontSize: 12, letterSpacing: 2, color: C.amber }}>
            {events.map(e => ` ★ ${fmtDate(e.date)} ${e.title} @${e.venue} `).join("・").repeat(3)}
          </div>
        </div>
      )}

      <main style={{ padding: "0 18px", maxWidth: 560, margin: "0 auto" }}>
        {loading && <div style={{ padding: 40, textAlign: "center", color: C.mute }}>載入中…</div>}

        {!loading && tab === "home" && (<>
          <SectionTitle zh="近期演出" en="UPCOMING SHOWS" />
          {events.length === 0 && <Empty text="還沒有活動——到「辦演出」建立第一場吧" />}
          {events.map(e => <TicketCard key={e.id} ev={e} />)}
          <SectionTitle zh="最新媒合" en="LATEST POSTS" />
          {posts.length === 0 && <Empty text="還沒有媒合貼文" />}
          {posts.slice(0, 3).map(p => <PostCard key={p.id} p={p} />)}
          <div style={{ textAlign: "center", margin: "6px 0 20px" }}>
            <Btn tone="ghost" onClick={() => setTab("gigs")}>查看全部媒合貼文 →</Btn>
          </div>
        </>)}

        {!loading && tab === "clubs" && (<>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <SectionTitle zh="社團名錄" en="CLUB DIRECTORY" />
            <Btn onClick={() => setModal({ type: "newClub" })}>＋ 登錄社團</Btn>
          </div>
          {clubs.map(c => (
            <div key={c.id} onClick={() => setModal({ type: "club", data: c })} style={{ background: C.card, border: `1px solid ${C.line}`, borderLeft: `3px solid ${C.amber}`, borderRadius: 6, padding: "13px 15px", marginBottom: 10, cursor: "pointer" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ fontWeight: 900, fontSize: 16, letterSpacing: 1 }}>{c.name}</div>
                <span style={{ fontSize: 11, color: C.mute }}>{c.area}</span>
              </div>
              <div style={{ fontSize: 12, color: C.mute, marginTop: 3 }}>{c.members} 位社員・{c.bands} 組樂團</div>
            </div>
          ))}
        </>)}

        {!loading && tab === "gigs" && (<>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <SectionTitle zh="表演媒合" en="GIG BOARD" />
            <Btn tone="pink" onClick={() => setModal({ type: "newPost" })}>＋ 發布</Btn>
          </div>
          <p style={{ fontSize: 12, color: C.mute, margin: "0 0 12px" }}>「徵團」= 我辦活動找樂團;「自薦」= 我的團找演出機會。</p>
          {posts.length === 0 && <Empty text="還沒有貼文,發第一篇吧" />}
          {posts.map(p => <PostCard key={p.id} p={p} />)}
        </>)}

        {!loading && tab === "venues" && (<>
          <SectionTitle zh="場地申請" en="VENUES" />
          {VENUES.map(v => (
            <div key={v.id} style={{ background: C.card, border: `1px solid ${C.line}`, borderRadius: 6, padding: "14px 15px", marginBottom: 12 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ fontWeight: 900, fontSize: 16 }}>{v.name}</div>
                <span style={{ fontSize: 11, color: C.mute }}>{v.area}</span>
              </div>
              <div style={{ display: "flex", gap: 6, margin: "7px 0" }}>{v.tags.map(t => <Tag key={t}>{t}</Tag>)}</div>
              <div style={{ fontSize: 13, color: C.mute, lineHeight: 1.6 }}>{v.note}</div>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 10 }}>
                <span style={{ fontFamily: "monospace", fontSize: 12, color: C.amber }}>容納 {v.cap} 人・{v.price}</span>
                <Btn onClick={() => setModal({ type: "apply", data: v })}>申請</Btn>
              </div>
            </div>
          ))}
          {myApps.length > 0 && (<>
            <SectionTitle zh="我的申請" en="MY APPLICATIONS" />
            {myApps.map(a => (
              <div key={a.id} style={{ background: C.card2, border: `1px dashed ${C.line}`, borderRadius: 6, padding: "12px 15px", marginBottom: 10 }}>
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <span style={{ fontWeight: 700 }}>{a.venue}</span>
                  <Tag tone="pink">{a.state}</Tag>
                </div>
                <div style={{ fontSize: 12, color: C.mute, marginTop: 4 }}>{a.club}・活動日期 {fmtDate(a.event_date)}</div>
              </div>
            ))}
          </>)}
        </>)}

        {!loading && tab === "host" && (<>
          <SectionTitle zh="辦一場演出" en="HOST A SHOW" />
          <p style={{ fontSize: 13, color: C.mute, lineHeight: 1.8, marginTop: 0 }}>建立活動後會顯示在首頁與跑馬燈。建議流程:確認合辦社團 → 申請場地 → 在媒合板徵團 → 公告活動。</p>
          <HostForm onSubmit={f => insert("events", f, "活動已建立並公開")} />
        </>)}
      </main>

      <nav style={{ position: "fixed", bottom: 0, left: 0, right: 0, zIndex: 40, background: "#120C10", borderTop: `1px solid ${C.line}`, display: "flex", justifyContent: "space-around", padding: "8px 4px calc(8px + env(safe-area-inset-bottom))" }}>
        {[["home", "首頁", "⌂"], ["clubs", "社團", "♫"], ["gigs", "媒合", "⇄"], ["host", "辦演出", "★"], ["venues", "場地", "▣"]].map(([k, label, icon]) => (
          <button key={k} onClick={() => setTab(k)} style={{ background: "none", border: "none", cursor: "pointer", color: tab === k ? C.amber : C.mute, fontFamily: "inherit", display: "flex", flexDirection: "column", alignItems: "center", gap: 2, fontSize: 11, letterSpacing: 1 }}>
            <span style={{ fontSize: 17 }}>{icon}</span>{label}
          </button>
        ))}
      </nav>

      {modal?.type === "club" && (
        <Modal title={modal.data.name} onClose={() => setModal(null)}>
          <p style={{ fontSize: 14, lineHeight: 1.8 }}>{modal.data.intro}</p>
          <div style={{ fontSize: 13, color: C.mute, marginBottom: 16 }}>{modal.data.members} 位社員・{modal.data.bands} 組樂團</div>
          <div style={{ background: C.bg, border: `1px solid ${C.line}`, borderRadius: 6, padding: "12px 14px", fontFamily: "monospace", fontSize: 14, color: C.amber }}>聯絡方式:{modal.data.contact}</div>
        </Modal>
      )}
      {modal?.type === "newClub" && <NewClubModal onClose={() => setModal(null)} onSubmit={f => insert("clubs", f, "社團已登錄名錄")} />}
      {modal?.type === "newPost" && <NewPostModal onClose={() => setModal(null)} onSubmit={f => insert("posts", f, "已發布,所有社團都看得到")} />}
      {modal?.type === "apply" && <ApplyModal venue={modal.data} onClose={() => setModal(null)} onSubmit={f => insert("venue_apps", f, "場地申請已送出", true)} />}

      {toast && <div style={{ position: "fixed", bottom: 84, left: "50%", transform: "translateX(-50%)", background: C.amber, color: "#1A1115", fontWeight: 800, fontSize: 13, padding: "10px 18px", borderRadius: 6, zIndex: 60, whiteSpace: "nowrap" }}>{toast}</div>}

      <style>{`
        @keyframes scrollX { from { transform: translateX(0); } to { transform: translateX(-33.33%); } }
        .marquee { animation: scrollX 30s linear infinite; }
        @media (prefers-reduced-motion: reduce) { .marquee { animation: none; } }
        input:focus, textarea:focus { border-color: ${C.amber} !important; }
        button:focus-visible { outline: 2px solid ${C.amber}; outline-offset: 2px; }
      `}</style>
    </div>
  );
}

const Empty = ({ text }) => (
  <div style={{ border: `1px dashed ${C.line}`, borderRadius: 6, padding: "22px 16px", textAlign: "center", color: C.mute, fontSize: 13, marginBottom: 12 }}>{text}</div>
);

function NewClubModal({ onClose, onSubmit }) {
  const [f, setF] = useState({ name: "", area: "", genre: "", members: "", bands: "", intro: "", contact: "" });
  const ok = f.name && f.area && f.contact;
  return (
    <Modal title="登錄社團" onClose={onClose}>
      <Field label="社團名稱 *" value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="例:○○高中 熱音社" />
      <Field label="地區 *" value={f.area} onChange={e => setF({ ...f, area: e.target.value })} placeholder="例:新北市.板橋" />
      <div style={{ display: "flex", gap: 10 }}>
        <div style={{ flex: 1 }}><Field label="社員數" type="number" value={f.members} onChange={e => setF({ ...f, members: e.target.value })} /></div>
        <div style={{ flex: 1 }}><Field label="樂團數" type="number" value={f.bands} onChange={e => setF({ ...f, bands: e.target.value })} /></div>
      </div>
      <Field label="社團介紹" rows={3} value={f.intro} onChange={e => setF({ ...f, intro: e.target.value })} />
      <Field label="聯絡方式 *" value={f.contact} onChange={e => setF({ ...f, contact: e.target.value })} placeholder="IG / Email" />
      <Btn disabled={!ok} style={{ width: "100%", opacity: ok ? 1 : .4 }} onClick={() => ok && onSubmit({ ...f, members: Number(f.members) || 0, bands: Number(f.bands) || 0 })}>登錄</Btn>
    </Modal>
  );
}

function NewPostModal({ onClose, onSubmit }) {
  const [f, setF] = useState({ kind: "徵團", club: "", title: "", body: "", contact: "" });
  const ok = f.club && f.title && f.body && f.contact;
  return (
    <Modal title="發布媒合貼文" onClose={onClose}>
      <div style={{ display: "flex", gap: 8, marginBottom: 14 }}>
        {["徵團", "自薦"].map(k => (
          <button key={k} onClick={() => setF({ ...f, kind: k })} style={{ flex: 1, padding: "10px 0", borderRadius: 4, cursor: "pointer", fontFamily: "inherit", fontWeight: 800, letterSpacing: 2, fontSize: 14, background: f.kind === k ? (k === "徵團" ? C.pink : C.amber) : "transparent", color: f.kind === k ? "#1A1115" : C.mute, border: f.kind === k ? "none" : `1px solid ${C.line}` }}>{k}</button>
        ))}
      </div>
      <Field label="社團名稱 *" value={f.club} onChange={e => setF({ ...f, club: e.target.value })} />
      <Field label="標題 *" value={f.title} onChange={e => setF({ ...f, title: e.target.value })} placeholder="一句話說明需求" />
      <Field label="內容 *" rows={4} value={f.body} onChange={e => setF({ ...f, body: e.target.value })} placeholder="時間、地點、曲風、時段長度、設備等" />
      <Field label="聯絡方式 *" value={f.contact} onChange={e => setF({ ...f, contact: e.target.value })} placeholder="IG / Email" />
      <Btn tone="pink" disabled={!ok} style={{ width: "100%", opacity: ok ? 1 : .4 }} onClick={() => ok && onSubmit(f)}>發布貼文</Btn>
    </Modal>
  );
}

function ApplyModal({ venue, onClose, onSubmit }) {
  const [f, setF] = useState({ club: "", event_date: "", size: "", contact: "", note: "" });
  const ok = f.club && f.event_date && f.contact;
  return (
    <Modal title={`申請場地:${venue.name}`} onClose={onClose}>
      <p style={{ fontSize: 12, color: C.mute, marginTop: 0 }}>{venue.note}</p>
      <Field label="申請社團 *" value={f.club} onChange={e => setF({ ...f, club: e.target.value })} />
      <Field label="活動日期 *" type="date" value={f.event_date} onChange={e => setF({ ...f, event_date: e.target.value })} />
      <Field label="預估人數" value={f.size} onChange={e => setF({ ...f, size: e.target.value })} />
      <Field label="聯絡方式 *" value={f.contact} onChange={e => setF({ ...f, contact: e.target.value })} />
      <Field label="備註" rows={3} value={f.note} onChange={e => setF({ ...f, note: e.target.value })} />
      <Btn disabled={!ok} style={{ width: "100%", opacity: ok ? 1 : .4 }} onClick={() => ok && onSubmit({ ...f, venue: venue.name })}>送出申請</Btn>
    </Modal>
  );
}

function HostForm({ onSubmit }) {
  const [f, setF] = useState({ title: "", host: "", date: "", time: "", venue: "", descr: "" });
  const ok = f.title && f.host && f.date && f.venue;
  return (
    <div style={{ background: C.card, border: `1px solid ${C.line}`, borderRadius: 6, padding: "16px 15px" }}>
      <Field label="活動名稱 *" value={f.title} onChange={e => setF({ ...f, title: e.target.value })} />
      <Field label="主辦單位 *" value={f.host} onChange={e => setF({ ...f, host: e.target.value })} placeholder="例:薇閣 × 明德" />
      <div style={{ display: "flex", gap: 10 }}>
        <div style={{ flex: 1 }}><Field label="日期 *" type="date" value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></div>
        <div style={{ flex: 1 }}><Field label="時間" type="time" value={f.time} onChange={e => setF({ ...f, time: e.target.value })} /></div>
      </div>
      <Field label="場地 *" value={f.venue} onChange={e => setF({ ...f, venue: e.target.value })} />
      <Field label="活動說明" rows={3} value={f.descr} onChange={e => setF({ ...f, descr: e.target.value })} />
      <Btn disabled={!ok} style={{ width: "100%", opacity: ok ? 1 : .4 }} onClick={() => ok && onSubmit(f)}>建立活動</Btn>
    </div>
  );
}

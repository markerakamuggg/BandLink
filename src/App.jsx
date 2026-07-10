import React, { useState, useEffect } from "react";
import { supabase, configured } from "./supabase.js";

/* ── 團聚 BandLink ─ 雙北高中熱音社互聯平台(Google 登入版) ── */

const C = {
  bg: "#191216", card: "#241B21", card2: "#2E2229", line: "#3A2C33",
  amber: "#FFB525", pink: "#FF4D6D", paper: "#F2EAE0", mute: "#9C8E95",
};

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

const EditBtn = ({ onClick }) => (
  <button onClick={e => { e.stopPropagation(); onClick(); }} aria-label="編輯" style={{ marginLeft: "auto", background: "none", border: `1px solid ${C.line}`, color: C.mute, borderRadius: 4, fontSize: 12, padding: "2px 8px", cursor: "pointer", fontFamily: "inherit" }}>✎ 編輯</button>
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

const igHandle = t => { const m = String(t || "").match(/@([A-Za-z0-9._]{2,30})/); return m ? m[1] : null; };

const IgChip = ({ from }) => {
  const h = igHandle(from);
  if (!h) return null;
  return (
    <a href={`https://www.instagram.com/${h}/`} target="_blank" rel="noreferrer" onClick={e => e.stopPropagation()}
      style={{ display: "inline-flex", alignItems: "center", gap: 4, fontFamily: "monospace", fontSize: 12, fontWeight: 700, color: "#1A1115", background: C.amber, borderRadius: 999, padding: "2px 10px", textDecoration: "none", whiteSpace: "nowrap" }}>
      ◎ @{h}
    </a>
  );
};

const ContactLine = ({ contact }) => {
  const h = igHandle(contact);
  return (
    <div style={{ fontFamily: "monospace", fontSize: 12, color: C.amber }}>
      聯絡:{h
        ? <a href={`https://www.instagram.com/${h}/`} target="_blank" rel="noreferrer" style={{ color: C.amber, textDecoration: "underline" }}>{contact}</a>
        : contact}
    </div>
  );
};

const TicketCard = ({ ev, onEdit }) => (
  <div style={{ display: "flex", background: C.card2, borderRadius: 6, overflow: "hidden", marginBottom: 14, border: `1px solid ${C.line}` }}>
    <div style={{ flex: 1, padding: "14px 16px" }}>
      <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 6 }}>
        <span style={{ fontFamily: "monospace", fontSize: 11, color: C.mute }}>{fmtDate(ev.date)}・{ev.time}</span>
        {onEdit && <EditBtn onClick={onEdit} />}
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
        <span style={{ fontSize: 17, fontWeight: 900, letterSpacing: 1, color: C.paper, lineHeight: 1.35 }}>{ev.title}</span>
        <IgChip from={`${ev.contact || ""} ${ev.host || ""} ${ev.descr || ""}`} />
      </div>
      <div style={{ fontSize: 13, color: C.amber, margin: "4px 0 6px" }}>{ev.host}</div>
      {ev.descr && <div style={{ fontSize: 13, color: C.mute, lineHeight: 1.6 }}>{ev.descr}</div>}
      <div style={{ fontSize: 12, color: C.paper, marginTop: 8 }}>📍 {ev.venue}</div>
      {ev.contact && <div style={{ marginTop: 6 }}><ContactLine contact={ev.contact} /></div>}
    </div>
    <div style={{ width: 56, borderLeft: `2px dashed ${C.line}`, display: "flex", alignItems: "center", justifyContent: "center", background: C.card }}>
      <span style={{ writingMode: "vertical-rl", fontFamily: "monospace", fontSize: 11, letterSpacing: 3, color: C.mute }}>ADMIT ONE</span>
    </div>
  </div>
);

const PostCard = ({ p, onEdit }) => (
  <div style={{ background: C.card, border: `1px solid ${C.line}`, borderRadius: 6, padding: "13px 15px", marginBottom: 10 }}>
    <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 6 }}>
      <Tag tone={p.kind === "徵團" ? "pink" : "amber"}>{p.kind}</Tag>
      <span style={{ fontSize: 12, color: C.mute }}>{p.club}・{fmtDate(p.created_at)}</span>
      {onEdit && <EditBtn onClick={onEdit} />}
    </div>
    <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
      <span style={{ fontWeight: 900, fontSize: 15, letterSpacing: .5, color: C.paper }}>{p.title}</span>
      <IgChip from={p.contact} />
    </div>
    <div style={{ fontSize: 13, color: C.mute, lineHeight: 1.7, margin: "5px 0 8px" }}>{p.body}</div>
    <ContactLine contact={p.contact} />
  </div>
);

/* ── 主程式 ── */
export default function App() {
  const [tab, setTab] = useState("home");
  const [session, setSession] = useState(null);
  const [clubs, setClubs] = useState([]);
  const [venues, setVenues] = useState([]);
  const [posts, setPosts] = useState([]);
  const [events, setEvents] = useState([]);
  const [myApps, setMyApps] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null);
  const [toast, setToast] = useState("");
  const [codeError, setCodeError] = useState(false);

  const ping = msg => { setToast(msg); setTimeout(() => setToast(""), 2600); };
  const uid = session?.user?.id || null;
  const isMine = item => uid && item.user_id === uid;

  useEffect(() => {
    if (!configured) return;
    supabase.auth.getSession().then(({ data }) => setSession(data.session));
    const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => setSession(s));
    return () => sub.subscription.unsubscribe();
  }, []);

  const login = () => supabase.auth.signInWithOAuth({ provider: "google", options: { redirectTo: window.location.origin } });
  const logout = async () => { await supabase.auth.signOut(); ping("已登出"); };

  // 需要登入的操作先過這關
  const requireLogin = next => {
    if (uid) setModal(next);
    else setModal({ type: "needLogin" });
  };

  const reload = async () => {
    if (!configured) { setLoading(false); return; }
    setLoading(true);
    try {
      const [c, p, e, v] = await Promise.all([
        supabase.from("clubs").select("*").order("created_at"),
        supabase.from("posts").select("*").order("created_at", { ascending: false }),
        supabase.from("events").select("*").order("date"),
        supabase.from("venues").select("*").order("created_at"),
      ]);
      setClubs(c.data || []); setPosts(p.data || []); setEvents(e.data || []); setVenues(v.data || []);
      const ids = JSON.parse(localStorage.getItem("my-app-ids") || "[]");
      if (ids.length) {
        const { data } = await supabase.from("venue_apps").select("*").in("id", ids).order("created_at", { ascending: false });
        setMyApps(data || []);
      }
    } catch (err) { console.error(err); ping("讀取資料失敗,請稍後再試"); }
    setLoading(false);
  };

  useEffect(() => { reload(); }, []);

  const create = async (table, row, okMsg) => {
    try {
      const { error } = await supabase.from(table).insert(row);
      if (error) throw error;
      setModal(null); ping(okMsg); reload();
    } catch (err) { console.error(err); ping("送出失敗,請確認已登入並檢查網路"); }
  };

  const update = async (table, id, fields, okMsg) => {
    try {
      const { error } = await supabase.from(table).update(fields).eq("id", id);
      if (error) throw error;
      setModal(null); ping(okMsg); reload();
    } catch (err) { console.error(err); ping("更新失敗,請檢查網路後再試"); }
  };

  const remove = async (table, id, okMsg) => {
    try {
      const { error } = await supabase.from(table).delete().eq("id", id);
      if (error) throw error;
      setModal(null); ping(okMsg); reload();
    } catch (err) { console.error(err); ping("刪除失敗,請檢查網路後再試"); }
  };

  // 認領舊內容(編輯碼時代發布的)
  const claim = async code => {
    try {
      const { data, error } = await supabase.rpc("claim_item", { p_code: code });
      if (error) throw error;
      if (!data) { setCodeError(true); return; }
      setModal(null); ping("認領成功,這筆內容已綁定你的帳號"); reload();
    } catch (err) { console.error(err); ping("操作失敗,請檢查網路後再試"); }
  };

  const insertApp = async row => {
    try {
      const { data, error } = await supabase.from("venue_apps").insert(row).select().single();
      if (error) throw error;
      const ids = JSON.parse(localStorage.getItem("my-app-ids") || "[]");
      localStorage.setItem("my-app-ids", JSON.stringify([data.id, ...ids]));
      setModal(null); ping("場地申請已送出"); reload();
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

  const userName = session?.user?.user_metadata?.name || session?.user?.email || "";

  return (
    <div style={{ minHeight: "100vh", background: C.bg, color: C.paper, fontFamily: "'Noto Sans TC','PingFang TC','Microsoft JhengHei',sans-serif", paddingBottom: 76 }}>
      <header style={{ padding: "18px 18px 0" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 10 }}>
          <h1 style={{ margin: 0, fontSize: 30, fontWeight: 900, letterSpacing: 4 }}>團<span style={{ color: C.pink }}>聚</span></h1>
          <span style={{ fontFamily: "monospace", fontSize: 11, letterSpacing: 3, color: C.amber }}>BANDLINK・雙北熱音社互聯</span>
          <span style={{ marginLeft: "auto" }}>
            {uid
              ? <button onClick={logout} style={{ background: "none", border: `1px solid ${C.line}`, color: C.mute, borderRadius: 999, fontSize: 11, padding: "3px 10px", cursor: "pointer", fontFamily: "inherit" }}>{userName.split("@")[0].slice(0, 10)}・登出</button>
              : <button onClick={login} style={{ background: C.paper, border: "none", color: "#1A1115", borderRadius: 999, fontSize: 11, fontWeight: 800, padding: "4px 12px", cursor: "pointer", fontFamily: "inherit" }}>G 登入</button>}
          </span>
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
          {events.map(e => <TicketCard key={e.id} ev={e} onEdit={isMine(e) ? () => setModal({ type: "editEvent", data: e }) : undefined} />)}
          <SectionTitle zh="最新媒合" en="LATEST POSTS" />
          {posts.length === 0 && <Empty text="還沒有媒合貼文" />}
          {posts.slice(0, 3).map(p => <PostCard key={p.id} p={p} onEdit={isMine(p) ? () => setModal({ type: "editPost", data: p }) : undefined} />)}
          <div style={{ textAlign: "center", margin: "6px 0 20px" }}>
            <Btn tone="ghost" onClick={() => setTab("gigs")}>查看全部媒合貼文 →</Btn>
          </div>
        </>)}

        {!loading && tab === "clubs" && (<>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <SectionTitle zh="社團名錄" en="CLUB DIRECTORY" />
            <Btn onClick={() => requireLogin({ type: "newClub" })}>＋ 登錄社團</Btn>
          </div>
          {clubs.map(c => (
            <div key={c.id} onClick={() => setModal({ type: "club", data: c })} style={{ background: C.card, border: `1px solid ${C.line}`, borderLeft: `3px solid ${C.amber}`, borderRadius: 6, padding: "13px 15px", marginBottom: 10, cursor: "pointer" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 8 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
                  <span style={{ fontWeight: 900, fontSize: 16, letterSpacing: 1 }}>{c.name}</span>
                  <IgChip from={c.contact} />
                </div>
                <span style={{ fontSize: 11, color: C.mute, whiteSpace: "nowrap" }}>{c.area}</span>
              </div>
              <div style={{ fontSize: 12, color: C.mute, marginTop: 3 }}>{c.members} 位社員</div>
            </div>
          ))}
        </>)}

        {!loading && tab === "gigs" && (<>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <SectionTitle zh="表演媒合" en="GIG BOARD" />
            <Btn tone="pink" onClick={() => requireLogin({ type: "newPost" })}>＋ 發布</Btn>
          </div>
          <p style={{ fontSize: 12, color: C.mute, margin: "0 0 6px" }}>「徵團」= 我辦活動找樂團;「自薦」= 我的團找演出機會。發布需登入,內容綁定你的帳號,任何裝置登入都能編輯。</p>
          <button onClick={() => requireLogin({ type: "claim" })} style={{ background: "none", border: "none", color: C.amber, fontSize: 12, textDecoration: "underline", cursor: "pointer", fontFamily: "inherit", padding: 0, margin: "0 0 12px" }}>以前用編輯碼發過內容?登入後在這裡認領 →</button>
          {posts.length === 0 && <Empty text="還沒有貼文,發第一篇吧" />}
          {posts.map(p => <PostCard key={p.id} p={p} onEdit={isMine(p) ? () => setModal({ type: "editPost", data: p }) : undefined} />)}
        </>)}

        {!loading && tab === "venues" && (<>
          <SectionTitle zh="場地申請" en="VENUES" />
          {venues.length === 0 && <Empty text="尚未有場地資料——管理者可至 Supabase 的 venues 表新增" />}
          {venues.map(v => (
            <div key={v.id} style={{ background: C.card, border: `1px solid ${C.line}`, borderRadius: 6, padding: "14px 15px", marginBottom: 12 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ fontWeight: 900, fontSize: 16 }}>{v.name}</div>
                <span style={{ fontSize: 11, color: C.mute }}>{v.area}</span>
              </div>
              <div style={{ display: "flex", gap: 6, margin: "7px 0", flexWrap: "wrap" }}>{(v.tags || "").split(",").filter(Boolean).map(t => <Tag key={t}>{t.trim()}</Tag>)}</div>
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
          <p style={{ fontSize: 13, color: C.mute, lineHeight: 1.8, marginTop: 0 }}>建立活動需登入,活動會顯示在首頁與跑馬燈,綁定你的帳號、任何裝置都能編輯。建議流程:確認合辦社團 → 申請場地 → 在媒合板徵團 → 公告活動。</p>
          {uid
            ? <EventForm onSubmit={f => create("events", f, "活動已建立並公開")} />
            : <div style={{ textAlign: "center", padding: "20px 0" }}><Btn onClick={login}>使用 Google 登入後建立活動</Btn></div>}
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
          <div style={{ fontSize: 13, color: C.pink, marginBottom: 8 }}>{modal.data.area}</div>
          <p style={{ fontSize: 14, lineHeight: 1.8 }}>{modal.data.intro}</p>
          <div style={{ fontSize: 13, color: C.mute, marginBottom: 16 }}>{modal.data.members} 位社員</div>
          <div style={{ background: C.bg, border: `1px solid ${C.line}`, borderRadius: 6, padding: "12px 14px", marginBottom: 14 }}><ContactLine contact={modal.data.contact} /></div>
          {isMine(modal.data) && <Btn tone="ghost" style={{ width: "100%" }} onClick={() => setModal({ type: "editClub", data: modal.data })}>✎ 編輯社團資料</Btn>}
        </Modal>
      )}

      {modal?.type === "newClub" && (
        <ClubFormModal onClose={() => setModal(null)}
          onSubmit={f => create("clubs", { ...f, members: Number(f.members) || 0 }, "社團已登錄名錄")} />
      )}
      {modal?.type === "editClub" && (
        <ClubFormModal initial={modal.data} onClose={() => setModal(null)}
          onSubmit={f => update("clubs", modal.data.id, { ...f, members: Number(f.members) || 0 }, "社團資料已更新")}
          onDelete={() => remove("clubs", modal.data.id, "社團已從名錄移除")} />
      )}

      {modal?.type === "newPost" && (
        <PostFormModal onClose={() => setModal(null)}
          onSubmit={f => create("posts", f, "已發布,所有人都看得到")} />
      )}
      {modal?.type === "editPost" && (
        <PostFormModal initial={modal.data} onClose={() => setModal(null)}
          onSubmit={f => update("posts", modal.data.id, f, "貼文已更新")}
          onDelete={() => remove("posts", modal.data.id, "貼文已刪除")} />
      )}

      {modal?.type === "editEvent" && (
        <Modal title="編輯活動" onClose={() => setModal(null)}>
          <EventForm initial={modal.data}
            onSubmit={f => update("events", modal.data.id, f, "活動已更新")}
            onDelete={() => remove("events", modal.data.id, "活動已刪除")} />
        </Modal>
      )}

      {modal?.type === "claim" && <ClaimModal onClose={() => setModal(null)} onSubmit={claim} />}

      {modal?.type === "needLogin" && (
        <Modal title="需要登入" onClose={() => setModal(null)}>
          <p style={{ fontSize: 14, color: C.paper, lineHeight: 1.9, marginTop: 0 }}>發布和編輯內容需要 Google 帳號登入——這樣不管你之後換手機、換電腦,登入後都能直接編輯自己的內容,也不用再記編輯碼。</p>
          <p style={{ fontSize: 12, color: C.mute, lineHeight: 1.8 }}>瀏覽內容不需要登入。</p>
          <Btn style={{ width: "100%" }} onClick={login}>使用 Google 登入</Btn>
        </Modal>
      )}

      {modal?.type === "apply" && <ApplyModal venue={modal.data} onClose={() => setModal(null)} onSubmit={insertApp} />}

      {codeError && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(10,6,8,.72)", zIndex: 70, display: "flex", alignItems: "center", justifyContent: "center", padding: 24 }}>
          <div style={{ width: "100%", maxWidth: 340, background: C.card, border: `2px solid ${C.pink}`, borderRadius: 10, padding: "22px 18px", textAlign: "center" }}>
            <div style={{ fontSize: 32, color: C.pink, marginBottom: 6 }}>✕</div>
            <h3 style={{ margin: "0 0 8px", fontSize: 18, fontWeight: 900, letterSpacing: 2, color: C.paper }}>編輯碼錯誤</h3>
            <p style={{ fontSize: 13, color: C.mute, lineHeight: 1.8, margin: "0 0 16px" }}>你輸入的編輯碼查無對應內容。請核對當初發布時取得的那組碼(格式如 A1B2-C3D4,大小寫和前後空格不影響)。</p>
            <Btn tone="pink" style={{ width: "100%" }} onClick={() => setCodeError(false)}>重新輸入</Btn>
          </div>
        </div>
      )}

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

const DeleteRow = ({ onDelete, label }) => (
  <button onClick={() => { if (window.confirm(`確定要刪除這筆${label}?此動作無法復原。`)) onDelete(); }}
    style={{ width: "100%", marginTop: 10, background: "none", border: `1px solid ${C.pink}`, color: C.pink, borderRadius: 4, padding: "9px 0", fontWeight: 800, fontSize: 13, letterSpacing: 1, cursor: "pointer", fontFamily: "inherit" }}>
    刪除這筆{label}
  </button>
);

function ClubFormModal({ initial, onClose, onSubmit, onDelete }) {
  const editing = Boolean(initial);
  const [f, setF] = useState(initial
    ? { name: initial.name, area: initial.area, members: String(initial.members ?? ""), intro: initial.intro || "", contact: initial.contact }
    : { name: "", area: "", members: "", intro: "", contact: "" });
  const ok = f.name && f.area && f.contact;
  return (
    <Modal title={editing ? "編輯社團資料" : "登錄社團"} onClose={onClose}>
      <Field label="社團名稱 *" value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="例:○○高中 熱音社" />
      <Field label="地區 *" value={f.area} onChange={e => setF({ ...f, area: e.target.value })} placeholder="例:新北市.板橋" />
      <Field label="社員數" type="number" value={f.members} onChange={e => setF({ ...f, members: e.target.value })} />
      <Field label="社團介紹" rows={3} value={f.intro} onChange={e => setF({ ...f, intro: e.target.value })} />
      <Field label="聯絡方式 *" value={f.contact} onChange={e => setF({ ...f, contact: e.target.value })} placeholder="IG / Email(填 @帳號 會變成可點的連結)" />
      <Btn disabled={!ok} style={{ width: "100%", opacity: ok ? 1 : .4 }} onClick={() => ok && onSubmit(f)}>{editing ? "儲存變更" : "登錄"}</Btn>
      {editing && <DeleteRow onDelete={onDelete} label="社團" />}
    </Modal>
  );
}

function PostFormModal({ initial, onClose, onSubmit, onDelete }) {
  const editing = Boolean(initial);
  const [f, setF] = useState(initial
    ? { kind: initial.kind, club: initial.club, title: initial.title, body: initial.body, contact: initial.contact }
    : { kind: "徵團", club: "", title: "", body: "", contact: "" });
  const ok = f.club && f.title && f.body && f.contact;
  return (
    <Modal title={editing ? "編輯媒合貼文" : "發布媒合貼文"} onClose={onClose}>
      <div style={{ display: "flex", gap: 8, marginBottom: 14 }}>
        {["徵團", "自薦"].map(k => (
          <button key={k} onClick={() => setF({ ...f, kind: k })} style={{ flex: 1, padding: "10px 0", borderRadius: 4, cursor: "pointer", fontFamily: "inherit", fontWeight: 800, letterSpacing: 2, fontSize: 14, background: f.kind === k ? (k === "徵團" ? C.pink : C.amber) : "transparent", color: f.kind === k ? "#1A1115" : C.mute, border: f.kind === k ? "none" : `1px solid ${C.line}` }}>{k}</button>
        ))}
      </div>
      <Field label="社團名稱 *" value={f.club} onChange={e => setF({ ...f, club: e.target.value })} />
      <Field label="標題 *" value={f.title} onChange={e => setF({ ...f, title: e.target.value })} placeholder="一句話說明需求" />
      <Field label="內容 *" rows={4} value={f.body} onChange={e => setF({ ...f, body: e.target.value })} placeholder="時間、地點、曲風、時段長度、設備等" />
      <Field label="聯絡方式 *" value={f.contact} onChange={e => setF({ ...f, contact: e.target.value })} placeholder="IG / Email(填 @帳號 會變成可點的連結)" />
      <Btn tone="pink" disabled={!ok} style={{ width: "100%", opacity: ok ? 1 : .4 }} onClick={() => ok && onSubmit(f)}>{editing ? "儲存變更" : "發布貼文"}</Btn>
      {editing && <DeleteRow onDelete={onDelete} label="貼文" />}
    </Modal>
  );
}

function EventForm({ initial, onSubmit, onDelete }) {
  const editing = Boolean(initial);
  const [f, setF] = useState(initial
    ? { title: initial.title, host: initial.host, date: String(initial.date || "").slice(0, 10), time: initial.time || "", venue: initial.venue, descr: initial.descr || "", contact: initial.contact || "" }
    : { title: "", host: "", date: "", time: "", venue: "", descr: "", contact: "" });
  const ok = f.title && f.host && f.date && f.venue;
  return (
    <div style={{ background: editing ? "transparent" : C.card, border: editing ? "none" : `1px solid ${C.line}`, borderRadius: 6, padding: editing ? 0 : "16px 15px" }}>
      <Field label="活動名稱 *" value={f.title} onChange={e => setF({ ...f, title: e.target.value })} />
      <Field label="主辦單位 *" value={f.host} onChange={e => setF({ ...f, host: e.target.value })} placeholder="例:薇閣 × 明德" />
      <div style={{ display: "flex", gap: 10 }}>
        <div style={{ flex: 1 }}><Field label="日期 *" type="date" value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></div>
        <div style={{ flex: 1 }}><Field label="時間" type="time" value={f.time} onChange={e => setF({ ...f, time: e.target.value })} /></div>
      </div>
      <Field label="場地 *" value={f.venue} onChange={e => setF({ ...f, venue: e.target.value })} />
      <Field label="聯絡方式" value={f.contact} onChange={e => setF({ ...f, contact: e.target.value })} placeholder="IG / Email(填 @帳號 會變成可點的連結)" />
      <Field label="活動說明" rows={3} value={f.descr} onChange={e => setF({ ...f, descr: e.target.value })} />
      <Btn disabled={!ok} style={{ width: "100%", opacity: ok ? 1 : .4 }} onClick={() => ok && onSubmit(f)}>{editing ? "儲存變更" : "建立活動"}</Btn>
      {editing && <DeleteRow onDelete={onDelete} label="活動" />}
    </div>
  );
}

function ClaimModal({ onClose, onSubmit }) {
  const [code, setCode] = useState("");
  return (
    <Modal title="認領舊內容" onClose={onClose}>
      <p style={{ fontSize: 13, color: C.mute, lineHeight: 1.8, marginTop: 0 }}>在登入功能上線前,用「編輯碼」發布過的內容還沒綁定帳號。輸入當初取得的編輯碼,即可把那筆內容認領到你目前登入的帳號,之後在任何裝置登入都能直接編輯。</p>
      <div style={{ background: C.bg, border: `1px dashed ${C.amber}`, borderRadius: 6, padding: "10px 12px", marginBottom: 14 }}>
        <div style={{ fontSize: 12, color: C.amber, marginBottom: 6, letterSpacing: 1 }}>編輯碼</div>
        <input value={code} onChange={e => setCode(e.target.value)} placeholder="例:A1B2-C3D4" style={{ ...inputStyle, fontFamily: "monospace", letterSpacing: 2 }} />
      </div>
      <Btn disabled={!code} style={{ width: "100%", opacity: code ? 1 : .4 }} onClick={() => code && onSubmit(code)}>認領</Btn>
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

import { createClient } from "@supabase/supabase-js";

const FOUR_DAYS_MS = 4 * 24 * 60 * 60 * 1000;
const FIVE_DAYS_MS = 5 * 24 * 60 * 60 * 1000;

export default async function handler(req, res) {
  if (req.headers.authorization !== `Bearer ${process.env.CRON_SECRET}`) {
    return res.status(401).json({ error: "unauthorized" });
  }

  const supabase = createClient(process.env.VITE_SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
  const createdCutoff = new Date(Date.now() - FOUR_DAYS_MS).toISOString();
  const expiresCutoff = new Date(Date.now() + FIVE_DAYS_MS).toISOString();

  const { data: subs, error } = await supabase
    .from("subs")
    .select("id, song, user_id")
    .eq("filled", false)
    .is("reminder_sent_at", null)
    .or(`created_at.lt.${createdCutoff},expires_at.lt.${expiresCutoff}`);

  if (error) return res.status(500).json({ error: error.message });

  let sent = 0;
  for (const sub of subs || []) {
    if (!sub.user_id) continue;

    const { data: userData } = await supabase.auth.admin.getUserById(sub.user_id);
    const email = userData?.user?.email;
    if (!email) continue;

    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: process.env.RESEND_FROM_EMAIL || "BandLink 團聚 <onboarding@resend.dev>",
        to: email,
        subject: `《${sub.song}》代打找到了嗎?`,
        html: `<p>你在團聚 BandLink 發布的代打貼文《${sub.song}》發布已滿 4 天,或報名截止日快到了。</p>
<p>如果已經找到人,登入 <a href="https://band-link.vercel.app/">band-link.vercel.app</a> 到「代打」分頁,把貼文勾選「已徵到人」,之後就不會再收到這封提醒信。</p>
<p>如果還在找,貼文會繼續留著,祝順利找到代打!</p>`,
      }),
    });

    if (resendRes.ok) {
      await supabase.from("subs").update({ reminder_sent_at: new Date().toISOString() }).eq("id", sub.id);
      sent++;
    }
  }

  res.status(200).json({ checked: subs?.length || 0, sent });
}

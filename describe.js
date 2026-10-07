// Vercel serverless function: AI listing-description generator (Anthropic API)
export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  try {
    const token = (req.headers.authorization || '').replace('Bearer ', '');
    const u = await fetch(`${process.env.SUPABASE_URL}/auth/v1/user`, {
      headers: { apikey: process.env.SUPABASE_ANON_KEY, Authorization: `Bearer ${token}` } });
    if (!u.ok) return res.status(401).json({ error: 'Login required' });
    const { title, category, price } = req.body || {};
    if (!title || String(title).length > 80) return res.status(400).json({ error: 'Valid title required' });
    const r = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-api-key': process.env.ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01' },
      body: JSON.stringify({ model: 'claude-haiku-4-5-20251001', max_tokens: 200,
        messages: [{ role: 'user', content: `Write a friendly, honest 2-3 sentence campus marketplace listing description for a student selling: "${title}" (category: ${category || 'other'}, price: ₹${price || '?'}). No emojis, no invented specs, mention they can ask about condition. Output only the description.` }] }) });
    const d = await r.json();
    if (!r.ok) return res.status(502).json({ error: 'AI service error' });
    res.json({ description: d.content?.[0]?.text?.trim() || '' });
  } catch (e) { res.status(500).json({ error: 'Server error' }); }
}

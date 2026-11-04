// Creates a login for every active member in Team Members (admin tool, run on your own computer).
// Needs Node 18 or newer.  Usage (see SETUP.md for where to find the values):
//   SUPABASE_URL=https://xxxx.supabase.co SERVICE_ROLE_KEY=eyJ... node create-users.mjs
//   add  --reset  to give EVERY listed person a new temporary password (also for existing logins)
// It writes new-logins.csv with each email and temporary password. Share these privately.
// The service role key is a master key: never put it in index.html or share it.
import { writeFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';

const URL_ = (process.env.SUPABASE_URL || '').replace(/\/$/, ''), KEY = process.env.SERVICE_ROLE_KEY || '';
const RESET = process.argv.includes('--reset');
if (!URL_ || !KEY) { console.error('Set SUPABASE_URL and SERVICE_ROLE_KEY first. See SETUP.md.'); process.exit(1); }
const H = { apikey: KEY, Authorization: 'Bearer ' + KEY, 'Content-Type': 'application/json' };
const tempPassword = () => { const a = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789', b = randomBytes(12); return Array.from(b, x => a[x % a.length]).join('') + '#7'; };

const members = await (await fetch(`${URL_}/rest/v1/qa_records?coll=eq.members&select=id,data&limit=1000`, { headers: H })).json();
if (!Array.isArray(members)) { console.error('Could not read Team Members:', JSON.stringify(members)); process.exit(1); }

const existing = new Map();   // email -> auth user id
for (let page = 1; page < 50; page++) {
  const r = await (await fetch(`${URL_}/auth/v1/admin/users?page=${page}&per_page=200`, { headers: H })).json();
  const list = r.users || [];
  list.forEach(u => existing.set((u.email || '').toLowerCase(), u.id));
  if (list.length < 200) break;
}

const rows = [['name', 'email', 'temporary_password', 'result']];
let created = 0, reset = 0, skipped = 0, failed = 0;
for (const m of members) {
  const d = m.data || {}, email = String(d.email || '').trim().toLowerCase();
  if ((d.status || 'Active') === 'Inactive' || !email) continue;
  const id = existing.get(email), password = tempPassword();
  try {
    if (!id) {
      const r = await fetch(`${URL_}/auth/v1/admin/users`, { method: 'POST', headers: H, body: JSON.stringify({ email, password, email_confirm: true, user_metadata: { name: d.name || '' } }) });
      if (!r.ok) throw new Error((await r.text()).slice(0, 120));
      rows.push([d.name, email, password, 'created']); created++;
    } else if (RESET) {
      const r = await fetch(`${URL_}/auth/v1/admin/users/${id}`, { method: 'PUT', headers: H, body: JSON.stringify({ password }) });
      if (!r.ok) throw new Error((await r.text()).slice(0, 120));
      rows.push([d.name, email, password, 'password reset']); reset++;
    } else { skipped++; }
  } catch (e) { rows.push([d.name, email, '', 'FAILED: ' + e.message]); failed++; }
}
const csv = rows.map(r => r.map(v => '"' + String(v ?? '').replace(/"/g, '""') + '"').join(',')).join('\n');
writeFileSync('new-logins.csv', csv);
console.log(`Created ${created}, reset ${reset}, already had a login ${skipped}, failed ${failed}.`);
console.log('Saved new-logins.csv. Share each password privately, then delete the file.');

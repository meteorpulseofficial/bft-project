// "Sign in as..." page for the demo copy: http://localhost:3001
// Each button makes a one-time sign-in link for a fake person and opens the app with it.
import http from "node:http";
import { admin, people } from "./lib.mjs";

const APP = "http://localhost:3000";
const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

const groups = [
  ["Running the business", ["owner", "gm", "finance"]],
  ["Studio managers", ["mgr-bgs", "mgr-sbj"]],
  ["Coaches", ["aisha", "ben", "chloe", "daniel", "emma", "faiz", "grace", "hafiz"]],
];

function page() {
  const byKey = Object.fromEntries(people.map((p) => [p.key, p]));
  const sections = groups
    .map(([title, keys]) => `<h2>${title}</h2><div class="grid">${keys
      .map((k) => byKey[k])
      .map((p) => `<a class="card" href="/go/${encodeURIComponent(p.key)}"><b>${esc(p.name)}</b><span>${esc(p.label)}</span></a>`)
      .join("")}</div>`)
    .join("");
  return `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Coach Hub demo: sign in as</title><style>
body{font-family:-apple-system,system-ui,sans-serif;max-width:860px;margin:0 auto;padding:24px 16px;background:#f6f6f4;color:#1b1b1b}
h1{font-size:22px;margin:0 0 4px}p{color:#555;margin:0 0 20px;line-height:1.45}h2{font-size:14px;text-transform:uppercase;letter-spacing:.06em;color:#777;margin:24px 0 8px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:10px}
.card{display:flex;flex-direction:column;gap:4px;padding:14px 16px;background:#fff;border:1px solid #e2e2de;border-radius:10px;text-decoration:none;color:inherit}
.card:hover{border-color:#999}.card span{color:#666;font-size:13px}.note{margin-top:28px;font-size:13px;color:#777}
</style></head><body><h1>Coach Hub demo copy</h1>
<p>Everything here is fake: made-up people, studios and classes. Nothing you do reaches Kelvin's real app or coaches.
Click a person to open the app signed in as them. To switch person, come back to this page and click another.</p>
${sections}<p class="note">Demo database only. Links work once and expire after an hour.</p></body></html>`;
}

http
  .createServer(async (req, res) => {
    const m = req.url.match(/^\/go\/([a-z-]+)$/);
    if (m) {
      const p = people.find((x) => x.key === m[1]);
      if (!p) return res.writeHead(404).end("Unknown person");
      const { data, error } = await admin.auth.admin.generateLink({ type: "magiclink", email: p.email });
      if (error) return res.writeHead(500).end(`Could not make a sign-in link: ${error.message}`);
      const url = `${APP}/auth/confirm?token_hash=${encodeURIComponent(data.properties.hashed_token)}&type=magiclink`;
      return res.writeHead(302, { Location: url }).end();
    }
    if (req.url === "/" || req.url === "") {
      return res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" }).end(page());
    }
    res.writeHead(404).end("Not found");
  })
  .listen(3001, "127.0.0.1", () => console.log("Sign-in page: http://localhost:3001"));

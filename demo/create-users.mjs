// Creates the 13 fake sign-in accounts (all @example.com) in the demo project. No emails are sent.
import { admin, people } from "./lib.mjs";

const { data: existing, error: listErr } = await admin.auth.admin.listUsers({ perPage: 200 });
if (listErr) throw listErr;
const have = new Set(existing.users.map((u) => u.email));

for (const p of people) {
  if (have.has(p.email)) {
    console.log(`exists   ${p.email}`);
    continue;
  }
  const { error } = await admin.auth.admin.createUser({
    email: p.email,
    email_confirm: true,
    user_metadata: { full_name: p.name, employment_type: p.type, phone: p.phone },
  });
  if (error) throw new Error(`${p.email}: ${error.message}`);
  console.log(`created  ${p.email}`);
}

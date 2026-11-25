// Shared helpers for the demo copy. Reads keys from app/.env.local and refuses to work
// unless they point at the demo project recorded in demo/.env.demo.
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
export const root = path.resolve(here, "..");

function readEnv(file) {
  const out = {};
  for (const line of readFileSync(file, "utf8").split("\n")) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m) out[m[1]] = m[2].replace(/^["']|["']$/g, "");
  }
  return out;
}

export const appEnv = readEnv(path.join(root, "app", ".env.local"));
export const demoEnv = readEnv(path.join(here, ".env.demo"));

const ref = demoEnv.DEMO_PROJECT_REF;
if (!ref || appEnv.NEXT_PUBLIC_SUPABASE_URL !== `https://${ref}.supabase.co`) {
  console.error("Refusing: app/.env.local does not point at the demo project in demo/.env.demo");
  process.exit(1);
}

const require = createRequire(path.join(root, "app", "package.json"));
const { createClient } = require("@supabase/supabase-js");

export const admin = createClient(appEnv.NEXT_PUBLIC_SUPABASE_URL, appEnv.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

export const people = JSON.parse(readFileSync(path.join(here, "people.json"), "utf8"));
for (const p of people) {
  if (!p.email.endsWith("@example.com")) throw new Error(`Not a demo email: ${p.email}`);
}

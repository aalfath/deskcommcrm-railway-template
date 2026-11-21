// Creates the first owner of a DeskcommCRM instance, once. A port of upstream's
// scripts/bootstrap-owner.ts (same four steps, same values) using fetch, because the app image
// is a standalone build without tsx or the script:
//   1. the owner's account in Supabase Auth, e-mail confirmed
//   2. the organisation (OWNER_ORG_NAME, default "Minha Empresa")
//   3. the owner's membership as admin
//   4. the owner's platform super-admin row (mfa_required false, as upstream sets it)
// Difference: upstream resets the owner password on every run because it runs once. This runs
// on every start, so it does nothing once a platform admin exists; a password changed in the app
// survives redeploys. Set DESKCOMM_RESET_OWNER_PASSWORD=true for one deploy to reset it to
// OWNER_PASSWORD.
const BASE = (process.env.SUPABASE_INTERNAL || "").replace(/\/+$/, "");
const KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || "";
const EMAIL = (process.env.OWNER_EMAIL || "").trim().toLowerCase();
const PASSWORD = process.env.OWNER_PASSWORD || "";
const ORG = (process.env.OWNER_ORG_NAME || "").trim() || "Minha Empresa";
const LOCALE = ["pt-BR", "es"].includes((process.env.APP_LOCALE || "").trim()) ? process.env.APP_LOCALE.trim() : "pt-BR";
const log = (m) => console.log(`[deskcomm-owner] ${m}`);

async function call(method, path, body, extra = {}) {
  const r = await fetch(BASE + path, {
    method,
    headers: { apikey: KEY, Authorization: `Bearer ${KEY}`, "Content-Type": "application/json", ...extra },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await r.text();
  if (!r.ok) throw new Error(`${method} ${path.split("?")[0]} -> HTTP ${r.status} ${text.slice(0, 200)}`);
  return text ? JSON.parse(text) : null;
}

async function findUser() {
  for (let page = 1; page <= 50; page++) {
    const d = await call("GET", `/auth/v1/admin/users?page=${page}&per_page=200`);
    const users = (d && d.users) || [];
    const hit = users.find((u) => (u.email || "").toLowerCase() === EMAIL);
    if (hit) return hit;
    if (users.length < 200) return null;
  }
  return null;
}

const slug = ORG.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase()
  .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 40) || "minha-empresa";

try {
  const admins = await call("GET", "/rest/v1/platform_admins?select=user_id&revoked_at=is.null&limit=1");
  if (admins.length) {
    if (process.env.DESKCOMM_RESET_OWNER_PASSWORD === "true") {
      const u = await findUser();
      if (u) {
        await call("PUT", `/auth/v1/admin/users/${u.id}`, { password: PASSWORD });
        log("owner password reset to OWNER_PASSWORD; remove DESKCOMM_RESET_OWNER_PASSWORD now");
      } else log("no account with OWNER_EMAIL; nothing reset");
    } else log("owner already set up; nothing to do");
    process.exit(0);
  }

  let user = await findUser();
  if (user) {
    await call("PUT", `/auth/v1/admin/users/${user.id}`, { password: PASSWORD, email_confirm: true });
  } else {
    user = await call("POST", "/auth/v1/admin/users", {
      email: EMAIL, password: PASSWORD, email_confirm: true, user_metadata: { full_name: "Dono", locale: LOCALE },
    });
    log("owner account created");
  }

  let org = (await call("GET", `/rest/v1/organizations?select=id&slug=eq.${encodeURIComponent(slug)}`))[0];
  if (!org) {
    org = (await call("POST", "/rest/v1/organizations",
      { slug, display_name: ORG, legal_name: ORG, locale: LOCALE, created_by: user.id },
      { Prefer: "return=representation" }))[0];
    log("organisation created");
  }

  const q = `user_id=eq.${user.id}&organization_id=eq.${org.id}`;
  if ((await call("GET", `/rest/v1/user_organizations?select=user_id&${q}`)).length) {
    await call("PATCH", `/rest/v1/user_organizations?${q}`, { role: "admin", revoked_at: null });
  } else {
    await call("POST", "/rest/v1/user_organizations",
      { user_id: user.id, organization_id: org.id, role: "admin", accepted_at: new Date().toISOString() });
  }

  await call("POST", "/rest/v1/platform_admins", {
    user_id: user.id, granted_by: user.id, scope: "full", mfa_required: false,
    reason: "Bootstrap inicial do self-host (dono da instância)",
  });
  log(`owner ready: ${EMAIL.replace(/^(.).*(@.*)$/, "$1***$2")} (super-admin of the instance)`);
} catch (e) {
  console.error(`[deskcomm-owner] ${e.message}`);
  process.exit(1);
}

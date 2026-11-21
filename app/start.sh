#!/bin/sh
# DeskcommCRM on Railway: prepare the database and the owner account, then start the web app.
#   1. derive the Supabase API keys from JWT_SECRET (same keys as every other service)
#   2. wait for Postgres, and for Supabase Auth and Storage (they create the auth and storage
#      schemas that DeskcommCRM's schema refers to)
#   3. apply supabase/baseline.sql (first boot) or re-apply it after a version change
#   4. seed the CPF and integration encryption keys into private.app_secrets, as upstream does
#   5. create the owner, organisation and super-admin role once (bootstrap-owner.mjs)
#   6. start Next.js on [::]:PORT
set -eu
log()  { printf '[deskcomm] %s\n' "$*"; }
fail() { printf '[deskcomm] FATAL: %s\n' "$*" >&2; exit 1; }

for v in JWT_SECRET SUPABASE_DB_URL NEXT_PUBLIC_SUPABASE_URL NEXT_PUBLIC_APP_URL INTERNAL_SECRET \
         CPF_ENCRYPTION_KEY AI_CRED_AES_KEY WAHA_BYO_ENCRYPTION_KEY NUVEMSHOP_OAUTH_ENCRYPTION_KEY \
         WAHA_API_BASE_URL WAHA_API_KEY WAHA_WEBHOOK_BASE_URL UPSTASH_REDIS_REST_URL UPSTASH_REDIS_REST_TOKEN \
         OWNER_EMAIL OWNER_PASSWORD; do
  eval "val=\${$v:-}"
  [ -n "$val" ] || fail "$v is not set"
done
[ "${#OWNER_PASSWORD}" -ge 12 ] || fail "OWNER_PASSWORD must be at least 12 characters"
case "$OWNER_EMAIL" in *@*.*) ;; *) fail "OWNER_EMAIL must be an e-mail address (you sign in with it)" ;; esac

# Defaults for a public deployment (upstream defaults in brackets):
#  - SIGNUP_MODE so_convite [aberto]: only invited people can create accounts; an open signup
#    would let any visitor create a company on this instance.
#  - SENTRY_DSN off [community Sentry]: no error reports leave the deployment unless you set one.
export SIGNUP_MODE="${SIGNUP_MODE:-so_convite}"
export SENTRY_DSN="${SENTRY_DSN:-off}"
export APP_LOCALE="${APP_LOCALE:-pt-BR}"
export PORT="${PORT:-3000}"
# Railway's private network is IPv6; the worker, the scheduler and WAHA's webhook reach the app over it.
export HOSTNAME="::"
# Server-side calls go to the gateway over the private network when SUPABASE_SERVER_URL is set.
SUPABASE_INTERNAL="${SUPABASE_SERVER_URL:-$NEXT_PUBLIC_SUPABASE_URL}"
export SUPABASE_INTERNAL

. /opt/deskcomm/supabase-keys.sh
export NEXT_PUBLIC_SUPABASE_ANON_KEY="$ANON_KEY"
export SUPABASE_SERVICE_ROLE_KEY="$SERVICE_ROLE_KEY"

deadline=$(( $(date +%s) + ${DESKCOMM_WAIT_SECONDS:-600} ))
wait_for() {
  what=$1; shift
  until "$@" >/dev/null 2>&1; do
    [ "$(date +%s)" -lt "$deadline" ] || fail "$what did not answer in time"
    sleep 3
  done
  log "$what is ready"
}
http_ok() { # path, key -> exit 0 on HTTP 200 through the gateway
  P="$1" K="$2" node -e 'fetch(process.env.SUPABASE_INTERNAL.replace(/\/+$/,"")+process.env.P,{headers:{apikey:process.env.K,Authorization:"Bearer "+process.env.K}}).then(r=>process.exit(r.status===200?0:1)).catch(()=>process.exit(1))'
}

wait_for "Postgres" psql "$SUPABASE_DB_URL" -tAc "select 1"
wait_for "Supabase Auth" http_ok /auth/v1/health "$ANON_KEY"
wait_for "Supabase Storage" http_ok /storage/v1/bucket "$SERVICE_ROLE_KEY"

/opt/deskcomm/apply-schema.sh

psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -q \
  -v cpf="$CPF_ENCRYPTION_KEY" -v nuvem="$NUVEMSHOP_OAUTH_ENCRYPTION_KEY" >/dev/null <<'SQL' || fail "could not seed the encryption keys"
insert into private.app_secrets (name, value) values ('cpf_key', :'cpf'), ('nuvemshop_oauth_key', :'nuvem')
on conflict (name) do update set value = excluded.value, updated_at = now();
notify pgrst, 'reload schema';
SQL

wait_for "Supabase REST with the DeskcommCRM schema" http_ok "/rest/v1/organizations?select=id&limit=1" "$SERVICE_ROLE_KEY"

node /opt/deskcomm/bootstrap-owner.mjs || fail "could not create the owner account"

log "signup: ${SIGNUP_MODE}; error reports: $([ "$SENTRY_DSN" = off ] && echo off || echo on)"
log "starting DeskcommCRM ${APP_VERSION:-} on [::]:${PORT}"
cd /app
exec node server.js

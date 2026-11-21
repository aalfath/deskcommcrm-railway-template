#!/bin/sh
# Starts the DeskcommCRM agent worker once the app service has applied this release's schema.
set -eu
log() { printf '[deskcomm-worker] %s\n' "$*"; }
: "${SUPABASE_DB_URL:?SUPABASE_DB_URL is required}"
export SENTRY_DSN="${SENTRY_DSN:-off}"
. /opt/deskcomm/supabase-keys.sh
export NEXT_PUBLIC_SUPABASE_ANON_KEY="$ANON_KEY"
export SUPABASE_SERVICE_ROLE_KEY="$SERVICE_ROLE_KEY"

check='const {Client}=require("pg");const c=new Client({connectionString:process.env.SUPABASE_DB_URL,connectionTimeoutMillis:5000});
c.connect().then(()=>c.query("select version from railway_template.schema_state")).then(r=>process.exit(r.rows[0]&&r.rows[0].version===process.env.APP_VERSION?0:1)).catch(()=>process.exit(1))'
i=0
until node -e "$check" 2>/dev/null; do
  [ $((i % 12)) -eq 0 ] && log "waiting for the app service to apply the ${APP_VERSION:-} schema"
  i=$((i + 1))
  [ "$i" -lt 240 ] || { echo "[deskcomm-worker] schema not ready after 20 minutes; check the app's log" >&2; exit 1; }
  sleep 5
done
log "schema ready; starting the agent worker"
cd /app
exec "$@"

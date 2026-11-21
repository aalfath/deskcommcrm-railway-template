#!/bin/sh
# Maps the template's variables to WAHA's, then runs WAHA's own entrypoint.
#  - WAHA_API_KEY arrives as plain text, the same value the app sends in X-Api-Key. WAHA's
#    entrypoint stores only its SHA-512 hash.
#  - WHATSAPP_HOOK_URL is the app's internal webhook (DESKCOMM_APP_HOST comes from Railway).
#  - WAHA_HMAC_SECRET signs every webhook (WHATSAPP_HOOK_HMAC_KEY is WAHA's name for it).
#  - Paired sessions live on the volume at /app/.sessions, so a redeploy doesn't ask for a new QR.
set -eu
: "${WAHA_API_KEY:?WAHA_API_KEY is required}"
: "${DESKCOMM_APP_HOST:?DESKCOMM_APP_HOST is required}"
export WHATSAPP_HOOK_URL="${WHATSAPP_HOOK_URL:-http://${DESKCOMM_APP_HOST}:${DESKCOMM_APP_PORT:-3000}/api/v1/webhooks/waha}"
[ -z "${WAHA_HMAC_SECRET:-}" ] || export WHATSAPP_HOOK_HMAC_KEY="$WAHA_HMAC_SECRET"
exec "$@"

#!/bin/sh
# Based on Supabase's docker/volumes/api/envoy/docker-entrypoint.sh, adapted for Railway and
# trimmed for DeskcommCRM: only the Auth, REST, Realtime and Storage APIs are routed (no Studio,
# Meta or Edge Functions), the API keys are derived from JWT_SECRET, and the upstream hosts come
# from variables.
set -e
. /usr/local/bin/supabase-keys.sh

: "${SUPABASE_PUBLIC_URL:?SUPABASE_PUBLIC_URL is required}"

# No route uses basic auth (there is no dashboard behind this gateway), but the filter stays in
# Supabase's chain, so give it a random credential nobody knows.
DASHBOARD_BASIC_AUTH="unused:{SHA}$(openssl rand -base64 32 | openssl sha1 -binary | openssl base64)"

echo "Generating Envoy configuration..."

# Using | as delimiter since JWT tokens contain /
sed -e "s|\${ANON_KEY}|${ANON_KEY}|g" \
    -e "s|\${ANON_KEY_ASYMMETRIC}|${ANON_KEY_ASYMMETRIC:-}|g" \
    -e "s|\${SERVICE_ROLE_KEY}|${SERVICE_ROLE_KEY}|g" \
    -e "s|\${SERVICE_ROLE_KEY_ASYMMETRIC}|${SERVICE_ROLE_KEY_ASYMMETRIC:-}|g" \
    -e "s|\${SUPABASE_PUBLISHABLE_KEY}|${SUPABASE_PUBLISHABLE_KEY:-}|g" \
    -e "s|\${SUPABASE_SECRET_KEY}|${SUPABASE_SECRET_KEY:-}|g" \
    -e "s|\${SUPABASE_PUBLIC_URL}|${SUPABASE_PUBLIC_URL}|g" \
    -e "s|\${DASHBOARD_BASIC_AUTH}|${DASHBOARD_BASIC_AUTH}|g" \
    /etc/envoy/lds.template.yaml > /etc/envoy/lds.yaml

sed -e "s|\${AUTH_HOST}|${AUTH_HOST:-auth}|g" \
    -e "s|\${REST_HOST}|${REST_HOST:-rest}|g" \
    -e "s|\${REALTIME_HOST}|${REALTIME_HOST:-realtime}|g" \
    -e "s|\${STORAGE_HOST}|${STORAGE_HOST:-storage}|g" \
    /etc/envoy/cds.template.yaml > /etc/envoy/cds.yaml

echo "Envoy running in legacy API key mode"
echo "Supabase API URL: ${SUPABASE_PUBLIC_URL}"
echo "Starting Envoy..."

exec envoy -c /etc/envoy/envoy.yaml "$@"

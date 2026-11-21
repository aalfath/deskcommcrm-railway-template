#!/bin/sh
# Applies DeskcommCRM's schema the way upstream's installer and update.sh do
# (hostgator-setup-kit/install.sh step 7 and reaplicar_baseline in _common.sh):
#  - empty database: create the extensions, then run baseline.sql with ON_ERROR_STOP;
#  - existing schema from another version: re-run baseline.sql (it is idempotent) and report
#    errors other than upstream's list of expected "already exists" ones.
# The applied version is kept in railway_template.schema_state, so a restart with the same
# version does nothing, and the worker waits until it matches its own version.
set -eu
log()  { printf '[deskcomm-schema] %s\n' "$*"; }
fail() { printf '[deskcomm-schema] FATAL: %s\n' "$*" >&2; exit 1; }
DB="$SUPABASE_DB_URL"
BASELINE=/opt/deskcomm/baseline.sql
VERSION="${APP_VERSION:?APP_VERSION missing from the image}"
OUT=/tmp/baseline.log
q() { psql "$DB" -tAc "$1" 2>/dev/null | tr -d '[:space:]'; }

psql "$DB" -v ON_ERROR_STOP=1 -q >/dev/null <<'SQL' || fail "could not create extensions and the version table"
create extension if not exists vector with schema public;
create extension if not exists citext with schema public;
create extension if not exists pg_trgm with schema public;
create schema if not exists railway_template;
revoke all on schema railway_template from public;
create table if not exists railway_template.schema_state (
  id boolean primary key default true check (id),
  version text not null,
  applied_at timestamptz not null default now()
);
SQL

has_schema=$(q "select 1 from information_schema.tables where table_schema='public' and table_name='organizations'")
applied=$(q "select version from railway_template.schema_state")

if [ "$has_schema" = 1 ] && [ "$applied" = "$VERSION" ]; then
  log "schema already at $VERSION"
elif [ "$has_schema" = 1 ]; then
  log "updating the schema from ${applied:-unknown} to $VERSION"
  { echo "select pg_advisory_lock(727272);"; cat "$BASELINE"; } | psql "$DB" -q >"$OUT" 2>&1 || true
  unexpected=$(grep -iE 'ERROR|FATAL' "$OUT" | grep -viE 'already exists|multiple primary keys|multiple default values|is already a member|already a partition' || true)
  if [ -n "$unexpected" ]; then
    log "WARNING: unexpected errors while updating the schema (first 10):"
    printf '%s\n' "$unexpected" | head -10 >&2
  fi
else
  log "empty database: applying the $VERSION schema (takes a minute)"
  if ! { echo "select pg_advisory_lock(727272);"; cat "$BASELINE"; } | psql "$DB" -v ON_ERROR_STOP=1 -q >"$OUT" 2>&1; then
    tail -5 "$OUT" >&2
    fail "the schema failed to apply; refusing to start without it"
  fi
fi

n=$(q "select count(*) from information_schema.tables where table_schema='public'")
[ "${n:-0}" -ge 100 ] || fail "only ${n:-0} tables in public after applying the schema"
psql "$DB" -v ON_ERROR_STOP=1 -q -v v="$VERSION" >/dev/null <<'SQL' || fail "could not record the schema version"
insert into railway_template.schema_state (id, version) values (true, :'v')
on conflict (id) do update set version = excluded.version, applied_at = now();
SQL
log "schema $VERSION ready ($n tables)"

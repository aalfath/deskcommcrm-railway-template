# Changelog

Breaking changes are listed first in each entry. Read the entry before you apply an update on Railway.

## 1.121.0-1 (2026-11-21): Deploy on Railway button

- No change to the deployed services. The README now starts with the Deploy on Railway button for the published template `deskcommcrm-1`.
- The `DeskcommCRM` app image now takes `psql` from the pinned `postgres:17.7-alpine3.22` image instead of installing it with `apk` (same psql 17 client; the build no longer needs a package mirror).

## 1.121.0 (2026-11-21): first release

- DeskcommCRM v1.121.0: app `ghcr.io/melgarafael/deskcommcrm:1.121.0`, worker `ghcr.io/melgarafael/deskcomm-worker:1.121.0`, scheduler `ghcr.io/melgarafael/deskcomm-scheduler:1.121.0`, each pinned by digest.
- Supabase services from Supabase's self-hosting kit (November 2026): Postgres `17.6.1.136`, Auth `v2.197.0`, PostgREST `v14.18`, Realtime `v2.148.3`, Storage `v1.89.12`, Envoy gateway `v1.39.6`.
- WAHA `noweb-2026.7.2` (the release upstream pins), serverless-redis-http (upstream's pinned build), Railway Redis.
- First boot applies the schema and creates the owner from `OWNER_EMAIL`; sign-up is invite-only; error reporting is off.

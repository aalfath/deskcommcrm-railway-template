[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/deskcommcrm-1?utm_medium=integration&utm_source=button&utm_campaign=deskcommcrm)

# DeskcommCRM on Railway

[DeskcommCRM](https://github.com/melgarafael/DeskcommCRM) (MIT) as a Railway template: the open-source sales CRM for businesses that sell over WhatsApp, with AI agents that answer, qualify and follow up, plus the self-hosted Supabase it runs on. Every service except Redis builds from this repository, so when `main` moves to a newer DeskcommCRM release, Railway offers the update to everyone who deployed the template.

Version: **DeskcommCRM 1.121.0** (upstream images pinned by version and digest).

## What it deploys

| Railway service | Folder | Upstream image | Role |
|---|---|---|---|
| `DeskcommCRM` | `app/` | `ghcr.io/melgarafael/deskcommcrm:1.121.0` | Web app (public domain). First boot applies the schema and creates the owner |
| `Worker` | `worker/` | `ghcr.io/melgarafael/deskcomm-worker:1.121.0` | AI agent worker, queues, follow-ups |
| `Scheduler` | `scheduler/` | `ghcr.io/melgarafael/deskcomm-scheduler:1.121.0` | Cron calls to the app's `/api/v1/cron/*` routes |
| `WAHA` | `waha/` | `devlikeapro/waha:noweb-2026.7.2` | WhatsApp connection (NOWEB engine), private; sessions on a volume |
| `Supabase` | `gateway/` | `envoyproxy/envoy:v1.39.6` | Supabase API gateway (public domain): `/auth/v1`, `/rest/v1`, `/realtime/v1`, `/storage/v1` |
| `Auth` | `auth/` | `supabase/gotrue:v2.197.0` | Sign-in and JWTs |
| `REST` | `rest/` | `postgrest/postgrest:v14.18` | REST API over the database |
| `Realtime` | `realtime/` | `supabase/realtime:v2.148.3` | Live updates in the inbox |
| `Storage` | `storage/` | `supabase/storage-api:v1.89.12` | Media, avatars and documents, on a volume |
| `Postgres` | `db/` | `supabase/postgres:17.6.1.136` | Supabase's Postgres 17 with its init scripts, on a volume |
| `SRH` | `srh/` | `hiett/serverless-redis-http` (upstream's pinned build) | Upstash-compatible REST bridge to Redis |
| `Redis` | (Railway) | Railway Redis | Rate limits and debounce |

Two services have public domains: `DeskcommCRM`, and `Supabase`, because the CRM's browser code talks to Supabase directly for sign-in, data under row-level security, Realtime and uploads. Everything else is on Railway's private network only.

Not included: WhatsApp voice calls (`wacalls`, needs UDP ports) and the Asterisk phone line (SIP/RTP over UDP); both are optional upstream profiles and Railway has no UDP ingress.

## Variables

The deploy form asks for one value:

| Service | Variable | Value |
|---|---|---|
| `DeskcommCRM` | `OWNER_EMAIL` | Your e-mail. The first boot creates this account as the instance owner and super-admin |

Generated per deployment: `OWNER_PASSWORD` (find it in the `DeskcommCRM` service's Variables tab), the Supabase `JWT_SECRET` (the anon and service-role API keys are derived from it at start), the Postgres and Redis passwords, `INTERNAL_SECRET`, the encryption keys (`CPF_ENCRYPTION_KEY`, `AI_CRED_AES_KEY`, `WAHA_BYO_ENCRYPTION_KEY`, `NUVEMSHOP_OAUTH_ENCRYPTION_KEY`), `IMPERSONATE_COOKIE_SECRET`, `LGPD_SIGNING_KEY`, the WAHA API key and webhook HMAC secret, and the SRH token. Everything else is a reference between services.

Defaults that differ from upstream, because a Railway deployment is public from the first minute:

- `SIGNUP_MODE=so_convite`: only invited people can create accounts (upstream: `aberto`, where any visitor gets a company of their own). Supabase Auth's public sign-up is closed to match.
- `SENTRY_DSN=off`: no error reports are sent to the project's community Sentry.

Optional settings (add them on the `DeskcommCRM` and `Worker` services): `OWNER_ORG_NAME` (company name, default "Minha Empresa"), `APP_LOCALE` (`pt-BR` or `es`), `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `OPENROUTER_API_KEY` (or add AI keys later in the app, stored encrypted), `SMTP_*` or `RESEND_API_KEY` for e-mail, `SENTRY_DSN` for your own Sentry. To open self-service sign-up, set `SIGNUP_MODE=aberto` on `DeskcommCRM` and `DISABLE_SIGNUP=false` on `Auth`.

## First steps

1. Open the `DeskcommCRM` domain. The first boot takes a few minutes (it applies a large schema).
2. Sign in with `OWNER_EMAIL` and the generated `OWNER_PASSWORD`, and change the password in the app.
3. Connect WhatsApp by scanning the QR code, and add an AI provider key.

Forgot the password? Set `DESKCOMM_RESET_OWNER_PASSWORD=true` on `DeskcommCRM` for one deploy, sign in with `OWNER_PASSWORD`, then remove the variable.

## Updates

This repo pins each image by version and digest. A new DeskcommCRM release lands here as a commit on `main` with a `CHANGELOG.md` entry, and Railway shows deployers an "update available" notice. Read the changelog first. When you apply an update, the app re-applies DeskcommCRM's schema (it is written to be re-run) before it serves, and the worker waits for it.

## Local test

`docker compose up -d --build`, then open `http://localhost:3000` and sign in as `owner@example.com` / `local-test-password`.

## Changes to upstream files

- `app/`: upstream's app image plus `psql`, `supabase/baseline.sql` from the worker image of the same release, and a start script that does what upstream's installer does from a shell (apply the schema, seed `cpf_key` and `nuvemshop_oauth_key` into `private.app_secrets`, create the owner with a port of `scripts/bootstrap-owner.ts`). Next.js listens on `::` for Railway's IPv6 private network.
- `worker/`: derives the Supabase keys from `JWT_SECRET` and waits for the schema. Upstream's command is unchanged.
- `scheduler/`: one line of upstream's entrypoint reads the app address from `DESKCOMM_APP_ORIGIN` instead of `http://app:3000`.
- `gateway/`: Supabase's Envoy config with only the Auth, REST, GraphQL, Realtime and Storage routes, a `/health` route without a key, and 404 for everything else (no Studio, Meta or Edge Functions).
- `db/`, `auth/`, `rest/`, `realtime/`, `storage/`: the wrappers of [aalfath/supabase-railway-template](https://github.com/aalfath/supabase-railway-template) (database on one volume, dual-stack listeners, waits on first boot, PostgREST watchdog). Auth has public sign-up off; Storage keeps files on its volume.

DeskcommCRM is MIT-licensed; Supabase's files keep their Apache-2.0 license. This template is not affiliated with the DeskcommCRM project.

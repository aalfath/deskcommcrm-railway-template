# DeskcommCRM agent worker: job queue, follow-ups, event-log drain and AI agent turns, 24/7.
# Upstream's image, unchanged, plus a start script that derives the Supabase API keys from
# JWT_SECRET and waits until the app has applied this release's schema.
FROM ghcr.io/melgarafael/deskcomm-worker:1.121.0@sha256:de891a69a607d68e156aee4432ad227427038a26005c3d2ac83f1ee356f5a676

COPY --chmod=755 supabase-keys.sh /opt/deskcomm/supabase-keys.sh
COPY --chmod=755 start.sh /opt/deskcomm/start.sh

ENTRYPOINT ["/opt/deskcomm/start.sh"]
CMD ["node", "--import", "tsx", "workers/agent-worker/main.ts"]

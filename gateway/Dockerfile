# Supabase API gateway (Envoy, Supabase's default gateway) for DeskcommCRM. The browser talks to
# it for sign-in, data under row-level security, Realtime and file uploads. It routes /auth/v1,
# /rest/v1, /graphql/v1, /realtime/v1 and /storage/v1, checks API keys, answers /health without
# a key, and returns 404 for everything else.
# Config files: Supabase's docker/volumes/api/envoy, with the changes noted in README.md.
FROM envoyproxy/envoy:v1.39.6@sha256:1fde8efee875e4e4f6a39a90fe49d9338e1caacce5762034ef9fb4bbb9ad6aed

COPY envoy.yaml /etc/envoy/envoy.yaml
COPY cds.template.yaml /etc/envoy/cds.template.yaml
COPY lds.template.yaml /etc/envoy/lds.template.yaml
COPY --chmod=755 supabase-keys.sh /usr/local/bin/supabase-keys.sh
COPY --chmod=755 docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/bin/sh", "/docker-entrypoint.sh"]

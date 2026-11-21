# DeskcommCRM web app (Next.js) for Railway.
#
# Upstream's installer applies supabase/baseline.sql, seeds two encryption keys into the database
# and creates the first owner from a shell before the app is usable. A one-click deploy has no
# such shell, so this wrapper does the same at start-up (start.sh) and only then starts the
# server. The application itself is upstream's image, unchanged.
#
# The app image is a Next.js standalone build without the schema, so baseline.sql comes from the
# worker image of the same release. Bump both pins (and worker/ and scheduler/) together.
FROM ghcr.io/melgarafael/deskcomm-worker:1.121.0@sha256:de891a69a607d68e156aee4432ad227427038a26005c3d2ac83f1ee356f5a676 AS schema

FROM ghcr.io/melgarafael/deskcommcrm:1.121.0@sha256:614ea10a1c313d9d2d968b2e3052e1541594868c3355c084288cd04441680204

USER root
# psql applies the schema (upstream's installer runs psql from a postgres:17 container).
RUN apk add --no-cache postgresql17-client && psql --version

COPY --from=schema /app/supabase/baseline.sql /opt/deskcomm/baseline.sql
COPY --chmod=755 supabase-keys.sh /opt/deskcomm/supabase-keys.sh
COPY --chmod=755 apply-schema.sh /opt/deskcomm/apply-schema.sh
COPY --chmod=644 bootstrap-owner.mjs /opt/deskcomm/bootstrap-owner.mjs
COPY --chmod=755 start.sh /opt/deskcomm/start.sh

# The schema in this image must belong to the app version in this image.
RUN test "$APP_VERSION" = "1.121.0" && grep -q 'create table' /opt/deskcomm/baseline.sql

USER nextjs
EXPOSE 3000
ENTRYPOINT ["/opt/deskcomm/start.sh"]

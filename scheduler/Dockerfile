# DeskcommCRM scheduler: BusyBox crond calling the app's /api/v1/cron/* routes with INTERNAL_SECRET.
# Upstream's image with one line changed: the app address is hard-coded to http://app:3000
# (a Docker Compose name); here it comes from DESKCOMM_APP_ORIGIN. The build fails if that line
# isn't found exactly once, so a bump that changes it can't slip through.
FROM ghcr.io/melgarafael/deskcomm-scheduler:1.121.0@sha256:1e66e0f2c82671298cb07e89afc2503a021439b8b3c8b07b0c8799b79ba1549a

RUN [ "$(grep -cxF 'APP_ORIGIN="http://app:3000"' /usr/local/bin/entrypoint.sh)" = 1 ] \
 && sed -i 's|^APP_ORIGIN="http://app:3000"$|APP_ORIGIN="${DESKCOMM_APP_ORIGIN:-http://app:3000}"|' /usr/local/bin/entrypoint.sh \
 && grep -q 'DESKCOMM_APP_ORIGIN' /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"]

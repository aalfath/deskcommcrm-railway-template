# serverless-redis-http: the Upstash-compatible REST bridge upstream DeskcommCRM runs in front of
# Redis (rate limits, debounce). Same build upstream pins in docker-compose.prod.yml (the image's
# `latest`, published 2024-05-11, by digest). Listens on [::]:80 for Railway's IPv6 private network.
FROM hiett/serverless-redis-http@sha256:5b0bb9239fce53abf87b2018a7a0deb9ec7bd900c5360738fe5fbeeb426f9150

ENV SRH_MODE=env \
    SRH_PORT=80 \
    SRH_IPV6=true
EXPOSE 80

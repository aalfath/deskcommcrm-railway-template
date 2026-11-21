# WAHA (WhatsApp HTTP API), NOWEB engine: the WhatsApp connection DeskcommCRM pairs by QR code.
# Same release upstream pins in docker-compose.prod.yml (2026.7.2), NOWEB variant (the engine
# upstream uses; no browser inside). Private only: the app calls it with WAHA_API_KEY and it posts
# events back to the app's internal webhook, signed with WHATSAPP_HOOK_HMAC_KEY.
FROM devlikeapro/waha:noweb-2026.7.2@sha256:33ecd1b782b2708db2ff1d366f51608889a036e76332dceae3fbbe3f10f2d75e

COPY --chmod=755 start.sh /usr/local/bin/railway-start.sh

ENV WHATSAPP_DEFAULT_ENGINE=NOWEB \
    WAHA_DASHBOARD_ENABLED=false \
    WHATSAPP_SWAGGER_ENABLED=false \
    WHATSAPP_RESTART_ALL_SESSIONS=True \
    WHATSAPP_HOOK_EVENTS=message.any,message.ack,message.edited,message.revoked,message.reaction,session.status,state.change,call.received \
    WHATSAPP_API_PORT=3000

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/railway-start.sh"]
CMD ["/entrypoint.sh"]

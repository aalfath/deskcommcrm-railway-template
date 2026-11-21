# Supabase Auth (GoTrue): sign-in and JWTs for DeskcommCRM (Supabase /auth/v1).
# Public sign-up is closed (DISABLE_SIGNUP=true), as upstream sets it for invite-only installs: the
# app creates accounts for invited people through the admin API. Set DISABLE_SIGNUP=false on this
# service together with SIGNUP_MODE=aberto on the app to open self-service sign-up.
FROM supabase/gotrue:v2.197.0@sha256:1736a63078f5922b198c4cbe50f80ab9a2d3b54fe8b7b6cfb2e9dc5dbbc12c6b

COPY --chmod=755 railway-start.sh /usr/local/bin/railway-start.sh

ENV GOTRUE_API_HOST="::" \
    GOTRUE_API_PORT=9999 \
    GOTRUE_DB_DRIVER=postgres \
    GOTRUE_JWT_ADMIN_ROLES=service_role \
    GOTRUE_JWT_AUD=authenticated \
    GOTRUE_JWT_DEFAULT_GROUP_NAME=authenticated \
    GOTRUE_JWT_EXP=3600 \
    GOTRUE_EXTERNAL_EMAIL_ENABLED=true \
    GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED=false \
    GOTRUE_EXTERNAL_PHONE_ENABLED=false \
    GOTRUE_SMS_AUTOCONFIRM=false \
    GOTRUE_DISABLE_SIGNUP=true \
    GOTRUE_MAILER_URLPATHS_INVITE=/auth/v1/verify \
    GOTRUE_MAILER_URLPATHS_CONFIRMATION=/auth/v1/verify \
    GOTRUE_MAILER_URLPATHS_RECOVERY=/auth/v1/verify \
    GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE=/auth/v1/verify

ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
CMD ["auth"]

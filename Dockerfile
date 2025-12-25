ARG N8N_VERSION=latest
ARG ALPINE_VERSION=3.22

FROM alpine:${ALPINE_VERSION} AS apktools
RUN apk add --no-cache apk-tools-static

FROM n8nio/n8n:${N8N_VERSION}

ARG ALPINE_VERSION

USER root

# Reinstall apk-tools since n8n removes it in the base image.
COPY --from=apktools /sbin/apk.static /sbin/apk.static
COPY --from=apktools /etc/apk/keys /tmp/apk-keys
RUN mkdir -p /etc/apk /etc/apk/keys \
    && cp -n /tmp/apk-keys/* /etc/apk/keys/ || true \
    && printf 'https://dl-cdn.alpinelinux.org/alpine/v%s/main\nhttps://dl-cdn.alpinelinux.org/alpine/v%s/community\n' "$ALPINE_VERSION" "$ALPINE_VERSION" > /etc/apk/repositories \
    && /sbin/apk.static -X "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" -U add apk-tools \
    && rm -f /sbin/apk.static \
    && rm -rf /tmp/apk-keys

RUN apk add --no-cache ffmpeg ffmpeg-dev \
    && rm -rf /var/cache/apk/*

# Switch back to the default user.
USER node

# Verify n8n and ffmpeg.
RUN n8n --version \
    && ffmpeg -version \
    && ffprobe -version

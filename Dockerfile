ARG N8N_VERSION=latest
ARG ALPINE_VERSION=3.22

FROM alpine:${ALPINE_VERSION} AS apktools
RUN apk add --no-cache apk-tools-static

FROM n8nio/n8n:${N8N_VERSION}

USER root

# Reinstall apk-tools since n8n removes it in the base image. The Alpine
# version is detected from the base image at build time so the package
# repositories always match the runtime base, even when upstream bumps
# its Alpine release. Detection uses /etc/os-release because the n8n base
# (Docker Hardened Images) ships no /etc/alpine-release.
COPY --from=apktools /sbin/apk.static /sbin/apk.static
COPY --from=apktools /etc/apk/keys /tmp/apk-keys
RUN RUNTIME_ALPINE_VERSION=$(. /etc/os-release && printf '%s' "$VERSION_ID" | cut -d. -f1,2) \
    && [ -n "$RUNTIME_ALPINE_VERSION" ] \
    && mkdir -p /etc/apk /etc/apk/keys \
    && { cp -n /tmp/apk-keys/* /etc/apk/keys/ || true; } \
    && printf 'https://dl-cdn.alpinelinux.org/alpine/v%s/main\nhttps://dl-cdn.alpinelinux.org/alpine/v%s/community\n' "$RUNTIME_ALPINE_VERSION" "$RUNTIME_ALPINE_VERSION" > /etc/apk/repositories \
    && /sbin/apk.static -X "https://dl-cdn.alpinelinux.org/alpine/v${RUNTIME_ALPINE_VERSION}/main" -U add apk-tools \
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

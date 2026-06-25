ARG N8N_VERSION=latest
# Pins only the donor stage that provides apk.static and signing keys (both
# work across newer Alpine releases); the runtime package repositories are
# detected from the base image instead.
ARG ALPINE_VERSION=3.22

FROM alpine:${ALPINE_VERSION} AS apktools
RUN apk add --no-cache apk-tools-static

FROM n8nio/n8n:${N8N_VERSION}

USER root

# n8n removes apk from the base image, so we bring back a working one. We do
# NOT reinstall the apk-tools package from the CDN: the base is a Docker
# Hardened Image whose /etc/apk/world pins every package to an exact content
# hash, and Alpine's main repo only keeps the latest point release. Once the
# CDN bumps apk-tools (e.g. 2.14.9 -> 2.14.10) a reinstall pulls a libapk2
# that no longer matches the pinned hash and the build breaks. Instead we keep
# the static apk binary from the donor stage as /sbin/apk: it never touches
# the pinned packages, installs ffmpeg cleanly, and leaves users a working apk
# for adding their own packages at runtime. The Alpine version is detected
# from /etc/os-release (the hardened base ships no /etc/alpine-release) so the
# repositories always match the runtime base, even across Alpine bumps.
COPY --from=apktools /sbin/apk.static /sbin/apk.static
COPY --from=apktools /etc/apk/keys /tmp/apk-keys
RUN RUNTIME_ALPINE_VERSION=$(. /etc/os-release && printf '%s' "$VERSION_ID" | cut -d. -f1,2) \
    && [ -n "$RUNTIME_ALPINE_VERSION" ] \
    && mkdir -p /etc/apk /etc/apk/keys \
    && { cp -n /tmp/apk-keys/* /etc/apk/keys/ || true; } \
    && printf 'https://dl-cdn.alpinelinux.org/alpine/v%s/main\nhttps://dl-cdn.alpinelinux.org/alpine/v%s/community\n' "$RUNTIME_ALPINE_VERSION" "$RUNTIME_ALPINE_VERSION" > /etc/apk/repositories \
    && /sbin/apk.static add --no-cache ffmpeg ffmpeg-dev \
    && mv /sbin/apk.static /sbin/apk \
    && rm -rf /tmp/apk-keys /var/cache/apk/*

# Switch back to the default user.
USER node

# Verify n8n and ffmpeg.
RUN n8n --version \
    && ffmpeg -version \
    && ffprobe -version

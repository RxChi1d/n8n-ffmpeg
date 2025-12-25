# Dockerfile variants

n8n-base removes apk-tools, so the official n8n image cannot use `apk add` directly. This project provides two Dockerfile variants.

## Table of contents

- [Why the original `apk add` approach fails](#apk-add-failure)
- [With apk-tools (default)](#with-apk-tools)
- [No apk-tools (clean install)](#no-apk-tools)

<a id="apk-add-failure"></a>
## Why the original `apk add` approach fails

We originally installed ffmpeg by running `apk add ffmpeg` in the Dockerfile. Starting from n8n-base, the `apk del apk-tools` step was moved into the final stage, so the official n8n image no longer includes `apk`. As a result, the original approach fails at build time and must be replaced by either restoring apk-tools or using a clean install.

Reference: n8n-base Dockerfile (release: [n8n@2.1.0](https://github.com/n8n-io/n8n/releases/tag/n8n%402.1.0), change: [PR #23149](https://github.com/n8n-io/n8n/pull/23149), [Line 45](https://github.com/n8n-io/n8n/blob/f4a43a273a776f4bf5a82c521a6490526182e694/docker/images/n8n-base/Dockerfile#L45))

<a id="with-apk-tools"></a>
## With apk-tools (default)

### Goal

Keep the official n8n base image and restore apk-tools so ffmpeg can be installed normally.

### Design notes

- n8n-base removes apk-tools, so `apk add` fails.
- Use a multi-stage build to copy `apk.static` and keys from Alpine, then install apk-tools in the final image.
- Avoid downloading `apk.static` directly to skip HTML parsing and avoid depending on tools like `grep` and `wget`.
- Merge keys with `cp -n` to avoid overwriting existing files.

### Usage

- Main Dockerfile: [`Dockerfile`](../Dockerfile)

```bash
docker build -t n8n-ffmpeg:local --build-arg N8N_VERSION=2.1.4 .
```

### When to use

- You need `apk` at runtime to install packages beyond ffmpeg.
- The most general choice if you do not require the smallest possible image.

<a id="no-apk-tools"></a>
## No apk-tools (clean install)

### Goal

Do not introduce apk or apk-tools into the final image. Only add the files required by ffmpeg and keep the result close to the official n8n image.

### Design notes

- Install ffmpeg in a builder stage on Alpine; do not bring apk or apk-tools into the final image.
- Copy only ffmpeg/ffprobe and required shared libraries into `/opt/ffmpeg` to avoid overwriting system files.
- Use wrappers to set `LD_LIBRARY_PATH` only when running ffmpeg.
- Minimize differences from the official n8n image.

### Usage

- Clean Dockerfile: [`Dockerfile.no-apk-tools`](../Dockerfile.no-apk-tools)

```bash
docker build -f Dockerfile.no-apk-tools -t n8n-ffmpeg:clean --build-arg N8N_VERSION=2.1.4 .
```

### When to use

- You only need ffmpeg and do not need to install other packages at runtime.
- You want the runtime environment to stay as close as possible to the official image.

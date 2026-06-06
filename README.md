# n8n-ffmpeg

[English](README.md) | [繁體中文](README.zh-tw.md)

[![Build Status](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/rxchi1d/n8n-ffmpeg/actions)
[![Check Updates Status](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/check-updates.yml/badge.svg)](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/check-updates.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/rxchi1d/n8n-ffmpeg?label=n8n-ffmpeg%20pulls)](https://hub.docker.com/r/rxchi1d/n8n-ffmpeg)
[![Docker Pulls (runners)](https://img.shields.io/docker/pulls/rxchi1d/n8n-runners-ffmpeg?label=n8n-runners-ffmpeg%20pulls)](https://hub.docker.com/r/rxchi1d/n8n-runners-ffmpeg)

Lightweight GitHub Actions workflow that periodically checks for new versions of the official n8n image, automatically builds and pushes multi-platform Docker images integrated with FFmpeg.

## Features

- **Version Monitoring**: Periodically checks [official n8n Docker Hub](https://hub.docker.com/r/n8nio/n8n) for new versions.
- **Automatic Build**: When a new version is detected, triggers a GitHub Actions workflow to build `linux/amd64` and `linux/arm64` images.
- **FFmpeg Integration**: Pre-installs FFmpeg in the base official n8n image, eliminating the need for manual installation.
- **Task Runners Image**: Also provides [`rxchi1d/n8n-runners-ffmpeg`](https://hub.docker.com/r/rxchi1d/n8n-runners-ffmpeg), an FFmpeg-enabled build of the official [`n8nio/runners`](https://hub.docker.com/r/n8nio/runners) sidecar image for task runners in `external` mode. See [Task Runners image](#task-runners-image-n8n-runners-ffmpeg).
- **Automatic Push**: Automatically pushes all tags (including version number and `latest`) to the specified Docker Hub Repository.

## Dockerfile variants

Since [n8n@2.1.0](https://github.com/n8n-io/n8n/releases/tag/n8n%402.1.0) ([PR #23149](https://github.com/n8n-io/n8n/pull/23149)), n8n-base removes apk-tools in the final stage. The official n8n image can no longer run `apk add` directly, so this project provides two variants.

- **Default (with apk-tools)**: `Dockerfile`, restores apk-tools via multi-stage and then installs FFmpeg.  
- **Clean (no apk-tools)**: `Dockerfile.no-apk-tools`, final image has no apk/apk-tools and only adds ffmpeg files.  

The same two variants exist for the task runners image: `Dockerfile.runners` (default, published) and `Dockerfile.runners.no-apk-tools` (clean, self-build).

Details:  
- [With apk-tools](docs/dockerfile-variants.md#with-apk-tools)  
- [No apk-tools](docs/dockerfile-variants.md#no-apk-tools)  
- [Task runners variants](docs/dockerfile-variants.md#runners)  

## Usage

1. **Pull the Image**

   ```bash
   docker pull rxchi1d/n8n-ffmpeg:latest
   ```

2. **Run the Container**

   ```bash
   docker run -d -it --rm \
     --name n8n-ffmpeg \
     -p 5678:5678 \
     -v appdata/n8n/data:/home/node/.n8n \
     rxchi1d/n8n-ffmpeg:latest
   ```

3. **Docker Compose (Optional)**

   ```yaml
   version: "3"
   services:
     n8n-ffmpeg:
       image: rxchi1d/n8n-ffmpeg:latest
       environment:
         # Required: Enable Execute Command node to use ffmpeg
         - NODES_EXCLUDE=[]

        <!-- Other configurations omitted -->
   ```
   The above is a simplified configuration example. For complete production environment configuration (including database, reverse proxy, etc.), please refer to the [official n8n Docker Compose example](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/#6-create-docker-compose-file).

   > [!IMPORTANT]
   > Starting from n8n@2.0.0, the `Execute Command` node is disabled by default for security reasons. To use `ffmpeg` and other commands in your workflow, you **must** add `NODES_EXCLUDE=[]` to the environment variables to enable all nodes.
   > For more details, please refer to the [official n8n documentation](https://docs.n8n.io/hosting/configuration/environment-variables/nodes/).

## Task Runners image (`n8n-runners-ffmpeg`)

When n8n runs [task runners](https://docs.n8n.io/hosting/configuration/task-runners/) in `external` mode, Code Node scripts execute in a separate sidecar container based on `n8nio/runners` — not in the main n8n container. In that setup, calling ffmpeg from a Code Node requires ffmpeg inside the runners image, so this project also provides `rxchi1d/n8n-runners-ffmpeg`:

- **FFmpeg pre-installed**, built and tagged automatically alongside the main image.
- **Configurable Code Node allowlists**: the official runners image hardcodes `NODE_FUNCTION_ALLOW_BUILTIN` and related variables in `/etc/n8n-task-runners.json`, silently discarding values set on the container. This image patches the config so they can be set via container environment variables. Defaults are identical to the official image — if you set nothing, behavior is unchanged.

```yaml
services:
  n8n:
    image: rxchi1d/n8n-ffmpeg:2.25.5
    environment:
      - NODES_EXCLUDE=[]
      - N8N_RUNNERS_ENABLED=true
      - N8N_RUNNERS_MODE=external
      - N8N_RUNNERS_AUTH_TOKEN=<shared-secret>

  runners:
    image: rxchi1d/n8n-runners-ffmpeg:2.25.5
    environment:
      - N8N_RUNNERS_AUTH_TOKEN=<shared-secret>
      - N8N_RUNNERS_TASK_BROKER_URI=http://n8n:5679
      # Opt-in: allow the JavaScript Code Node to spawn ffmpeg via child_process
      - NODE_FUNCTION_ALLOW_BUILTIN=crypto,child_process
```

> [!IMPORTANT]
> - Calling ffmpeg from a **JavaScript** Code Node requires `child_process` in `NODE_FUNCTION_ALLOW_BUILTIN`; from a **Python** Code Node, add `subprocess` to `N8N_RUNNERS_STDLIB_ALLOW`. Without these the runner keeps the official defaults and blocks process spawning.
> - Pin both images to the **same n8n version tag** instead of `latest` — the two images are built independently and may briefly point to different versions right after an n8n release.
> - The `Execute Command` node always runs in the main n8n container (it does not use task runners), so it relies on the main image's ffmpeg.

## 📖 Documentation

For a detailed introduction and implementation guide, please visit:
- [n8n-ffmpeg: n8n Docker Image with FFmpeg Integration and Automated Builds](https://inktrace.rxchi1d.me/en/posts/container-platform/n8n-ffmpeg/)

## CI Workflow

- **build-and-push.yml**:
  - **Trigger Conditions**: Called by the `check-updates.yml` workflow, or manually triggered.
  - **Main Steps**:
    - Resolves the image variant (`main` → `Dockerfile` / `rxchi1d/n8n-ffmpeg`, `runners` → `Dockerfile.runners` / `rxchi1d/n8n-runners-ffmpeg`).
    - Sets up Docker Buildx environment and logs in to Docker Hub.
    - Builds and pushes multi-architecture Docker images for `linux/amd64` and `linux/arm64` platforms, using the specified n8n version number and `latest` as tags.
- **check-updates.yml**:
  - **Trigger Conditions**: Runs automatically periodically (currently set to every 6 hours), or manually triggered.
  - **Main Steps**:
    - Fetches the latest version number from the official n8n GitHub repository.
    - For each variant independently, checks whether our image already exists on Docker Hub and whether the upstream image (`n8nio/n8n` / `n8nio/runners`) for that version has been published.
    - Triggers `build-and-push.yml` separately for each variant that needs building, so one variant lagging upstream never blocks the other.

## Acknowledgements

Thanks to the authors and contributors of the [n8n](https://github.com/n8n-io/n8n) project. This project is based on their outstanding work.

## License

This project is based on [n8n](https://n8n.io/) and is licensed under the [n8n Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md). A copy of the license is included in the [LICENSE.md](LICENSE.md) file in this repository.

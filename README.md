# n8n-ffmpeg

[English](README.md) | [繁體中文](README.zh-tw.md)

[![Build Status](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/rxchi1d/n8n-ffmpeg/actions)
[![Check Updates Status](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/check-updates.yml/badge.svg)](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/check-updates.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/rxchi1d/n8n-ffmpeg)](https://hub.docker.com/r/rxchi1d/n8n-ffmpeg)

Lightweight GitHub Actions workflow that periodically checks for new versions of the official n8n image, automatically builds and pushes multi-platform Docker images integrated with FFmpeg.

## Features

- **Version Monitoring**: Periodically checks [official n8n Docker Hub](https://hub.docker.com/r/n8nio/n8n) for new versions.
- **Automatic Build**: When a new version is detected, triggers a GitHub Actions workflow to build `linux/amd64` and `linux/arm64` images.
- **FFmpeg Integration**: Pre-installs FFmpeg in the base official n8n image, eliminating the need for manual installation.
- **Automatic Push**: Automatically pushes all tags (including version number and `latest`) to the specified Docker Hub Repository.

## Dockerfile variants

Since [n8n@2.1.0](https://github.com/n8n-io/n8n/releases/tag/n8n%402.1.0) ([PR #23149](https://github.com/n8n-io/n8n/pull/23149)), n8n-base removes apk-tools in the final stage. The official n8n image can no longer run `apk add` directly, so this project provides two variants.

- **Default (with apk-tools)**: `Dockerfile`, restores apk-tools via multi-stage and then installs FFmpeg.  
- **Clean (no apk-tools)**: `Dockerfile.no-apk-tools`, final image has no apk/apk-tools and only adds ffmpeg files.  

Details:  
- [With apk-tools](docs/dockerfile-variants.md#with-apk-tools)  
- [No apk-tools](docs/dockerfile-variants.md#no-apk-tools)  

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
       ports:
         - "5678:5678"
       volumes:
         - appdata/n8n/data:/home/node/.n8n
   ```

## 📖 Documentation

For a detailed introduction and implementation guide, please visit:
- [n8n-ffmpeg: n8n Docker Image with FFmpeg Integration and Automated Builds](https://inktrace.rxchi1d.me/en/posts/container-platform/n8n-ffmpeg/)

## CI Workflow

- **build-and-push.yml**:
  - **Trigger Conditions**: Called by the `check-updates.yml` workflow, or manually triggered.
  - **Main Steps**:
    - Checks out code.
    - Sets up Docker Buildx environment.
    - Logs in to Docker Hub.
    - Builds and pushes multi-architecture Docker images for `linux/amd64` and `linux/arm64` platforms, using the specified n8n version number and `latest` as tags.
- **check-updates.yml**:
  - **Trigger Conditions**: Runs automatically periodically (currently set to every 6 hours), or manually triggered.
  - **Main Steps**:
    - Checks out code.
    - Fetches the latest version number from the official n8n GitHub repository.
    - Checks if an image with that version number already exists in Docker Hub.
    - If it's a new version, then calls the `build-and-push.yml` workflow to build and push the new image.

## Acknowledgements

Thanks to the authors and contributors of the [n8n](https://github.com/n8n-io/n8n) project. This project is based on their outstanding work.

## License

This project is based on [n8n](https://n8n.io/) and is licensed under the [n8n Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md). A copy of the license is included in the [LICENSE.md](LICENSE.md) file in this repository.

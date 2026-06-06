# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Task runners image (`rxchi1d/n8n-runners-ffmpeg`) extending `n8nio/runners` with FFmpeg, in the same two variants as the main image (`Dockerfile.runners` and `Dockerfile.runners.no-apk-tools`). ([#4](https://github.com/RxChi1d/n8n-ffmpeg/issues/4))
- Runners Dockerfiles patch `/etc/n8n-task-runners.json` so the Code Node module allowlists (`NODE_FUNCTION_ALLOW_BUILTIN`, `NODE_FUNCTION_ALLOW_EXTERNAL`, `N8N_RUNNERS_STDLIB_ALLOW`, `N8N_RUNNERS_EXTERNAL_ALLOW`) become configurable via container environment variables, with defaults identical to the official image.
- Default runners variant detects the base image's Alpine version from `/etc/alpine-release` at build time instead of hardcoding it.
- README (English and zh-tw) section for the task runners image with an `external` mode Docker Compose example.

### Changed
- `build-and-push.yml` accepts a `variant` input (`main` / `runners`) that resolves the Dockerfile and target image, with per-variant build cache scopes.
- `check-updates.yml` checks each variant independently and triggers builds separately, so one variant lagging upstream never blocks the other.

## [1.0.0] - 2025-12-25

### Added
- Default Dockerfile variant restores apk-tools before installing FFmpeg.
- Clean Dockerfile variant (`Dockerfile.no-apk-tools`) that keeps the final image free of apk/apk-tools.
- Combined Dockerfile variants documentation with anchored sections for deep linking.
- English documentation for Dockerfile variants.

### Changed
- README (English and zh-tw) now documents the n8n@2.1.0 change that moved apk-tools removal to the final stage.
- README (English and zh-tw) now links to the Dockerfile variants document sections.

[Unreleased]: https://github.com/rxchi1d/n8n-ffmpeg/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/rxchi1d/n8n-ffmpeg/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/rxchi1d/n8n-ffmpeg/releases/tag/v0.1.0

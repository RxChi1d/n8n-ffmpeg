# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

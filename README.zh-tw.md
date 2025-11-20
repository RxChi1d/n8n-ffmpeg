# n8n-ffmpeg

[English](README.md) | [繁體中文](README.zh-tw.md)

[![Build Status](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/rxchi1d/n8n-ffmpeg/actions)
[![Check Updates Status](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/check-updates.yml/badge.svg)](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/check-updates.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/rxchi1d/n8n-ffmpeg)](https://hub.docker.com/r/rxchi1d/n8n-ffmpeg)

輕量化 GitHub Actions 工作流程，定期檢測 n8n 官方映像新版本，自動構建並推送集成 FFmpeg 的多平台 Docker 映像。

## 功能

- **版本監控**：定期檢查 [n8n 官方 Docker Hub](https://hub.docker.com/r/n8nio/n8n) 是否有新版本。  
- **自動構建**：檢測到新版本時，觸發 GitHub Actions 工作流程，構建 `linux/amd64` 與 `linux/arm64` 映像。  
- **FFmpeg 整合**：在官方 n8n 基礎映像中預裝 FFmpeg，免去手動安裝步驟。  
- **自動推送**：將所有標籤（含版本號及 `latest`）自動推送到指定的 Docker Hub Repository。  

## 使用說明

1. **拉取映像**

   ```bash
   docker pull rxchi1d/n8n-ffmpeg:latest
   ```

2. **執行容器**

   ```bash
   docker run -d -it --rm \
     --name n8n-ffmpeg \
     -p 5678:5678 \
     -v appdata/n8n/data:/home/node/.n8n \
     rxchi1d/n8n-ffmpeg:latest
   ```

3. **Docker Compose（選用）**

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

## 📖 相關文章

想了解更詳細的專案介紹與實作說明，請參考：
- [n8n-ffmpeg：整合 FFmpeg 的 n8n Docker 映像檔與自動化構建實作](https://inktrace.rxchi1d.me/posts/container-platform/n8n-ffmpeg/)

## CI 工作流程

- **build-and-push.yml**：
  - **觸發條件**：由 `check-updates.yml` 工作流程呼叫，或手動觸發。
  - **主要步驟**：
    - 檢查程式碼。
    - 設定 Docker Buildx 環境。
    - 登入 Docker Hub。
    - 構建並推送適用於 `linux/amd64` 和 `linux/arm64` 平台的多架構 Docker 映像，使用指定的 n8n 版本號和 `latest` 作為標籤。
- **check-updates.yml**：
  - **觸發條件**：定期（目前設定為每 6 小時）自動運行，或手動觸發。
  - **主要步驟**：
    - 檢查程式碼。
    - 獲取 n8n 官方 GitHub 儲存庫的最新版本號。
    - 檢查 Docker Hub 中是否已存在該版本號的映像。
    - 如果是新版本，則呼叫 `build-and-push.yml` 工作流程來構建和推送新映像。

## 致謝

感謝 [n8n](https://github.com/n8n-io/n8n) 專案的作者和貢獻者，本專案基於他們的傑出工作。

## 授權

本專案基於 [n8n](https://n8n.io/)，並遵循 [n8n Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md) 授權條款。授權條款的副本已包含在本儲存庫的 [LICENSE.md](LICENSE.md) 檔案中。

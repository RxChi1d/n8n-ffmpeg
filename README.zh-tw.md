# n8n-ffmpeg

[English](README.md) | [繁體中文](README.zh-tw.md)

[![Build Status](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/rxchi1d/n8n-ffmpeg/actions)
[![Check Updates Status](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/check-updates.yml/badge.svg)](https://github.com/rxchi1d/n8n-ffmpeg/actions/workflows/check-updates.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/rxchi1d/n8n-ffmpeg?label=n8n-ffmpeg%20pulls)](https://hub.docker.com/r/rxchi1d/n8n-ffmpeg)
[![Docker Pulls (runners)](https://img.shields.io/docker/pulls/rxchi1d/n8n-runners-ffmpeg?label=n8n-runners-ffmpeg%20pulls)](https://hub.docker.com/r/rxchi1d/n8n-runners-ffmpeg)

輕量化 GitHub Actions 工作流程，定期檢測 n8n 官方映像新版本，自動構建並推送集成 FFmpeg 的多平台 Docker 映像。

## 功能

- **版本監控**：定期檢查 [n8n 官方 Docker Hub](https://hub.docker.com/r/n8nio/n8n) 是否有新版本。  
- **自動構建**：檢測到新版本時，觸發 GitHub Actions 工作流程，構建 `linux/amd64` 與 `linux/arm64` 映像。  
- **FFmpeg 整合**：在官方 n8n 基礎映像中預裝 FFmpeg，免去手動安裝步驟。  
- **Task Runners 映像**：另提供 [`rxchi1d/n8n-runners-ffmpeg`](https://hub.docker.com/r/rxchi1d/n8n-runners-ffmpeg)，為官方 [`n8nio/runners`](https://hub.docker.com/r/n8nio/runners) sidecar 映像（`external` 模式的 task runners）整合 FFmpeg。詳見 [Task Runners 映像](#task-runners-映像n8n-runners-ffmpeg)。  
- **自動推送**：將所有標籤（含版本號及 `latest`）自動推送到指定的 Docker Hub Repository。  

## Dockerfile 版本

自 [n8n@2.1.0](https://github.com/n8n-io/n8n/releases/tag/n8n%402.1.0) 起，n8n-base 移除了 apk-tools ，導致官方 n8n 映像中無法直接使用 `apk add`。因此需要做調整。

- **預設版本（含 apk-tools）**：`Dockerfile`，透過 multi-stage 恢復 apk-tools，再安裝 FFmpeg。  
- **乾淨版本（不含 apk-tools）**：`Dockerfile.no-apk-tools`，最終映像不含 apk/apk-tools，僅加入 ffmpeg 必要檔案，與官方 n8n 差異最小。  

Task runners 映像也提供相同的兩種版本：`Dockerfile.runners`（預設，自動發布）與 `Dockerfile.runners.no-apk-tools`（乾淨版本，自行建置）。

詳細說明請見：  
- [含 apk-tools 版本](docs/dockerfile-variants.zh-tw.md#with-apk-tools)  
- [不含 apk-tools 版本](docs/dockerfile-variants.zh-tw.md#no-apk-tools)  
- [Task runners 版本](docs/dockerfile-variants.zh-tw.md#runners)  

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
       environment:
         # 必要設定：啟用 Execute Command 節點以使用 ffmpeg
         - NODES_EXCLUDE=[]

        <!-- 以下省略 -->
   ```
   以上為簡化的配置示例。完整的生產環境配置（包含資料庫、反向代理等），請參考 [n8n 官方 Docker Compose 範例](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/#6-create-docker-compose-file)。

   > [!IMPORTANT]
   > 從 n8n@2.0.0 開始，基於安全性考量，`Execute Command` 節點預設被停用。若要在 Workflow 中使用 `ffmpeg` 等指令，**必須**在環境變數中添加 `NODES_EXCLUDE=[]` 來解除所有節點的停用狀態。
   > 詳細資訊請參閱 [n8n 官方文件](https://docs.n8n.io/hosting/configuration/environment-variables/nodes/)。


## Task Runners 映像（`n8n-runners-ffmpeg`）

當 n8n 以 `external` 模式執行 [task runners](https://docs.n8n.io/hosting/configuration/task-runners/) 時，Code Node 的程式碼會在獨立的 sidecar 容器（基於 `n8nio/runners`）中執行，而非主 n8n 容器。在這種部署下，Code Node 要呼叫 ffmpeg，runners 映像本身就必須包含 ffmpeg，因此本專案另外提供 `rxchi1d/n8n-runners-ffmpeg`：

- **預裝 FFmpeg**，與主映像共用相同的自動建置與標籤策略。
- **可設定的 Code Node 模組允許清單**：官方 runners 映像將 `NODE_FUNCTION_ALLOW_BUILTIN` 等變數硬編碼在 `/etc/n8n-task-runners.json` 中，容器上設定的值會被靜默丟棄。本映像修補了該配置，使其可透過容器環境變數設定。預設值與官方映像完全一致——不設定就沒有任何行為差異。

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
      # Opt-in：允許 JavaScript Code Node 透過 child_process 呼叫 ffmpeg
      - NODE_FUNCTION_ALLOW_BUILTIN=crypto,child_process
```

> [!IMPORTANT]
> - **JavaScript** Code Node 呼叫 ffmpeg 需在 `NODE_FUNCTION_ALLOW_BUILTIN` 中加入 `child_process`；**Python** Code Node 則需在 `N8N_RUNNERS_STDLIB_ALLOW` 中加入 `subprocess`。未設定時 runner 維持官方預設行為，禁止建立子程序。
> - 請將兩個映像固定在**相同的 n8n 版本標籤**，避免使用 `latest`——兩個映像獨立建置，在 n8n 發布新版後的短暫期間可能指向不同版本。
> - `Execute Command` 節點永遠在主 n8n 容器中執行（不經過 task runners），使用的是主映像的 ffmpeg。

## 📖 相關文章

想了解更詳細的專案介紹與實作說明，請參考：
- [n8n-ffmpeg：整合 FFmpeg 的 n8n Docker 映像檔與自動化構建實作](https://inktrace.rxchi1d.me/posts/container-platform/n8n-ffmpeg/)

## CI 工作流程

- **build-and-push.yml**：
  - **觸發條件**：由 `check-updates.yml` 工作流程呼叫，或手動觸發。
  - **主要步驟**：
    - 解析映像變體（`main` → `Dockerfile` / `rxchi1d/n8n-ffmpeg`，`runners` → `Dockerfile.runners` / `rxchi1d/n8n-runners-ffmpeg`）。
    - 設定 Docker Buildx 環境並登入 Docker Hub。
    - 構建並推送適用於 `linux/amd64` 和 `linux/arm64` 平台的多架構 Docker 映像，使用指定的 n8n 版本號和 `latest` 作為標籤。
- **check-updates.yml**：
  - **觸發條件**：定期（目前設定為每 6 小時）自動運行，或手動觸發。
  - **主要步驟**：
    - 獲取 n8n 官方 GitHub 儲存庫的最新版本號。
    - 對每個變體獨立檢查：我們的映像是否已存在於 Docker Hub、該版本的官方上游映像（`n8nio/n8n` / `n8nio/runners`）是否已發布。
    - 對需要建置的變體分別觸發 `build-and-push.yml`——任一變體的上游延遲不會阻塞另一個變體。

## 致謝

感謝 [n8n](https://github.com/n8n-io/n8n) 專案的作者和貢獻者，本專案基於他們的傑出工作。

## 授權

本專案基於 [n8n](https://n8n.io/)，並遵循 [n8n Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md) 授權條款。授權條款的副本已包含在本儲存庫的 [LICENSE.md](LICENSE.md) 檔案中。

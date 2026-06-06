# Dockerfile 版本說明

n8n-base 已移除 apk-tools，因此官方 n8n 映像中無法直接使用 `apk add`。本專案提供兩個 Dockerfile 版本，依需求選用。

## 目錄

- [為什麼原本的 `apk add` 方式失效](#apk-add-failure)
- [含 apk-tools（預設）](#with-apk-tools)
- [不含 apk-tools（乾淨安裝）](#no-apk-tools)
- [Task runners 映像版本](#runners)

<a id="apk-add-failure"></a>
## 為什麼原本的 `apk add` 方式失效

原先我們在 Dockerfile 直接使用 `apk add ffmpeg` 安裝 ffmpeg。後來官方將 `apk del apk-tools` 移到 n8n-base 的 final stage，導致 n8n 映像本身不再包含 `apk`。因此原本的安裝方式會在建置階段失效，必須改成「恢復 apk-tools」或「乾淨安裝」兩種路線。

參考程式碼：n8n-base Dockerfile（版本：[n8n@2.1.0](https://github.com/n8n-io/n8n/releases/tag/n8n%402.1.0)，變更：[PR #23149](https://github.com/n8n-io/n8n/pull/23149)，[Line 45](https://github.com/n8n-io/n8n/blob/f4a43a273a776f4bf5a82c521a6490526182e694/docker/images/n8n-base/Dockerfile#L45)）

<a id="with-apk-tools"></a>
## 含 apk-tools（預設）

### 目的

在保留官方 n8n 映像為基礎的前提下，恢復 apk-tools，讓 ffmpeg 可以正常安裝。

### 設計重點

- 透過 multi-stage 從 Alpine 映像取得 `apk.static` 與 keys，再在最終映像中安裝 apk-tools。
- 不直接下載 `apk.static`：避免解析網頁或動態抓版本，也避免依賴 `grep`、`wget` 等工具，流程更可預期。
- keys 以 `cp -n` 合併到既有路徑，避免覆蓋原有資料。
- 套件來源的 Alpine 版本在建置時從 base 映像的 `/etc/os-release` 偵測，確保永遠與 runtime base 匹配，即使上游升級 Alpine 也不受影響。使用 `/etc/os-release` 是因為 n8n 的 base（Docker Hardened Images）不含 `/etc/alpine-release`。

### 使用方式

- 主要 Dockerfile：[`Dockerfile`](../Dockerfile)

```bash
docker build -t n8n-ffmpeg:local --build-arg N8N_VERSION=2.1.4 .
```

### 適用情境

- 除了 ffmpeg 之外，還需要在執行期使用 `apk` 安裝其他套件。
- 最通用的選擇，若不特別追求最小體積。

<a id="no-apk-tools"></a>
## 不含 apk-tools（乾淨安裝）

### 目的

在最終映像中完全不引入 apk 或 apk-tools，盡量貼近官方 n8n 映像，只加入 ffmpeg 所需檔案。

### 設計重點

- 使用 builder stage 在 Alpine 內安裝 ffmpeg，最終映像不帶入 apk 或 apk-tools。
- 僅複製 ffmpeg/ffprobe 與必要的動態函式庫到 `/opt/ffmpeg`，避免覆蓋系統檔案。
- 透過 wrapper 設定 `LD_LIBRARY_PATH`，僅在執行 ffmpeg 時生效。
- 最終映像與官方 n8n 的差異最小化。

### 使用方式

- 乾淨版本 Dockerfile：[`Dockerfile.no-apk-tools`](../Dockerfile.no-apk-tools)

```bash
docker build -f Dockerfile.no-apk-tools -t n8n-ffmpeg:clean --build-arg N8N_VERSION=2.1.4 .
```

### 適用情境

- 只需要 ffmpeg，不需要在執行期安裝其他套件。
- 希望執行環境更接近原始官方映像。

<a id="runners"></a>
## Task runners 映像版本

相同的兩種做法也適用於官方 [`n8nio/runners`](https://hub.docker.com/r/n8nio/runners) 映像（`external` 模式 task runners 的 sidecar），該映像同樣在 final stage 移除了 apk-tools：

- **預設版本（含 apk-tools）**：[`Dockerfile.runners`](../Dockerfile.runners)，發布為 `rxchi1d/n8n-runners-ffmpeg`。
- **乾淨版本（不含 apk-tools）**：[`Dockerfile.runners.no-apk-tools`](../Dockerfile.runners.no-apk-tools)，僅供自行建置。

### 與主映像版本的差異

- **Alpine 版本動態偵測（預設版本）**：與主 `Dockerfile` 相同的 `/etc/os-release` 偵測機制。對 runners 更為重要，因為其 runtime base（`python:3.13-alpine`）的 Alpine 版本不固定，若寫死 `ALPINE_VERSION`，當 base 映像升級 Alpine 時會靜默產生套件來源不匹配的問題。
- **Code Node 允許清單可設定化（兩種版本皆有）**：官方 runners 映像將 `NODE_FUNCTION_ALLOW_BUILTIN`、`NODE_FUNCTION_ALLOW_EXTERNAL`、`N8N_RUNNERS_STDLIB_ALLOW`、`N8N_RUNNERS_EXTERNAL_ALLOW` 硬編碼在 `/etc/n8n-task-runners.json` 的 `env-overrides` 中，導致 launcher 靜默丟棄容器上設定的值。兩種版本都會在建置時修補該配置，將這些變數移至 launcher 的 `allowed-env` 白名單，並以映像層級的 `ENV` 設定與官方相同的預設值。未明確覆寫時行為與官方完全一致（例如設定 `NODE_FUNCTION_ALLOW_BUILTIN=crypto,child_process` 即可讓 JavaScript Code Node 呼叫 ffmpeg）。

### 使用方式

```bash
docker build -f Dockerfile.runners -t n8n-runners-ffmpeg:local --build-arg N8N_VERSION=2.25.5 .
docker build -f Dockerfile.runners.no-apk-tools -t n8n-runners-ffmpeg:clean --build-arg N8N_VERSION=2.25.5 .
```

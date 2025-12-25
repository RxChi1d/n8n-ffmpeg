# Dockerfile 版本說明

n8n-base 已移除 apk-tools，因此官方 n8n 映像中無法直接使用 `apk add`。本專案提供兩個 Dockerfile 版本，依需求選用。

## 目錄

- [為什麼原本的 `apk add` 方式失效](#apk-add-failure)
- [含 apk-tools（預設）](#with-apk-tools)
- [不含 apk-tools（乾淨安裝）](#no-apk-tools)

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
- 不直接下載 `apk.static`：避免解析網頁或動態抓版本，也避免依賴 `grep`、`wget` 等工具，流程更可預期，也更容易固定 Alpine 版本來源。
- keys 以 `cp -n` 合併到既有路徑，避免覆蓋原有資料。

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

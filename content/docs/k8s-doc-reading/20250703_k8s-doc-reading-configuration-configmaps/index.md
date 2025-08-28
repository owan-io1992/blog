---
date: 2025-07-03T00:25:00
draft: false
tags:
- k8s-reading
title: "Concepts - configuration - configmaps"
weight: 22
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/configuration/configmap/)
[doc link](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

## 什麼是 ConfigMap？

**ConfigMap** 是 Kubernetes (K8s) 中用來儲存**非機密性**設定資料的 API 物件。它的核心價值在於**將設定與應用程式映像檔 (Image) 分離**。

想像一下，如果您的資料庫連線位址、功能開關 (feature flags) 或環境變數都寫死在程式碼或 Dockerfile 中，那麼每次需要變更設定時，您都必須重新建置、推送並部署新的映像檔。這不僅效率低下，也使得同一個映像檔無法輕易地在不同環境（如開發、測試、生產）中使用。

ConfigMap 解決了這個問題。您可以將設定資料以 key-value 的形式儲存在 ConfigMap 中，然後在 Pod 啟動時，以環境變數或掛載成檔案的方式動態地注入到容器內。

> **注意**：ConfigMap 不適合用來儲存敏感資訊（如密碼、API 金鑰），因為它的內容是以明文形式儲存的。對於敏感資訊，請使用 [Secret](@/docs/k8s-doc-reading/20250703_k8s-doc-reading-configuration-secrets/index.md)。

## 如何建立 ConfigMap？

ConfigMap 的 `data` 欄位中儲存了 key-value 形式的設定。其中，key 可以是簡單的屬性，也可以是檔名；value 則一律是字串，並支援多行內容。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: game-demo
  namespace: default
data:
  # 1. 類似屬性的 key-value
  player_initial_lives: "3"
  ui_properties_file_name: "user-interface.properties"

  # 2. 類似檔案的 key-value (key 是檔名，value 是檔案內容)
  game.properties: |
    enemy.types=aliens,monsters
    player.maximum-lives=5
  user-interface.properties: |
    color.good=purple
    color.bad=yellow
    allow.textmode=true
```

您也可以使用 `kubectl create configmap` 指令從檔案或字面值來建立 ConfigMap。

## 如何在 Pod 中使用 ConfigMap？

有四種主要的方式可以將 ConfigMap 的資料注入到容器中：

### 1. 注入為環境變數

您可以將 ConfigMap 中的特定 key 的值，注入為容器的一個環境變數。

```yaml
# ... spec.containers ...
env:
  - name: PLAYER_LIVES
    valueFrom:
      configMapKeyRef:
        name: game-demo # ConfigMap 的名稱
        key: player_initial_lives # 要引用的 key
```

### 2. 注入為容器命令列參數

一旦設定被注入為環境變數，您就可以在容器的 `command` 或 `args` 中引用它。

```yaml
# ... spec.containers ...
command: [ "/bin/sh", "-c" ]
args:
  - echo "Initial lives: $(PLAYER_LIVES)"
```
> **注意**：在 K8s manifest 中引用環境變數的語法是 `$(VAR_NAME)`。

### 3. 掛載為 Volume 中的檔案

這是最常用也最靈活的方式。您可以將 ConfigMap 中的一個或多個 key 掛載成一個目錄下的檔案。

```yaml
# ... spec.containers ...
volumeMounts:
- name: config-volume
  mountPath: /etc/config

# ... spec ...
volumes:
- name: config-volume
  configMap:
    name: game-demo
    # items 欄位可以選擇性地只掛載特定的 key
    items:
    - key: "game.properties"
      path: "game.properties" # path 是掛載後的檔名
    - key: "user-interface.properties"
      path: "ui.properties" # 可以自訂檔名
```
如果省略 `.items` 欄位，則 `data` 中的每一個 key 都會成為掛載目錄下的一個檔案。

### 4. 一次性注入所有 key-value 為環境變數

使用 `envFrom` 可以將 ConfigMap 中所有的 key-value 一次性地注入為容器的環境變數。

```yaml
# ... spec.containers ...
envFrom:
- configMapRef:
    name: game-demo
```

## 重要注意事項

### 自動更新的行為差異

這是 ConfigMap 最重要也最容易混淆的特性：

| 使用方式 | 是否會自動更新？ | 說明 |
| :--- | :--- | :--- |
| **掛載為 Volume** (不使用 `subPath`) | **是** | 當 ConfigMap 變更後，掛載到 Pod 內的檔案內容會**最終**被更新。`kubelet` 會定期同步，但這個過程有延遲。 |
| **注入為環境變數** | **否** | 環境變數是在容器啟動時注入的，是靜態的。如果 ConfigMap 變更，必須**重啟 Pod** 才能讀取到新值。 |
| **掛載為 Volume** (使用 `subPath`) | **否** | 使用 `subPath` 掛載的檔案**不會**自動更新。 |

> **最佳實踐**：為了確保設定變更的一致性，推薦的做法是採用滾動更新 (Rolling Update) 的方式來部署設定變更，而不是依賴 ConfigMap 的自動更新特性。

### 不可變的 ConfigMap (Immutable)

對於不希望被意外修改的重要設定，您可以將 ConfigMap 設為 `immutable` (不可變)。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-immutable-config
data:
  # ...
immutable: true
```

這樣做有兩個好處：
1.  **防止意外變更**：保護設定檔不被意外更新，從而避免可能導致的應用程式故障。
2.  **提升效能**：`kubelet` 不再需要監控 (watch) 這個 ConfigMap 的變化，從而減輕了 `kube-apiserver` 的負載。

---

總結來說，ConfigMap 是 K8s 中實現「設定與程式碼分離」這一重要原則的關鍵工具，它讓您的應用程式部署變得更加靈活和標準化。

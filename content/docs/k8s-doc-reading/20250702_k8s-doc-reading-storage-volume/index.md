---
date: 2025-07-02T09:41:00
draft: false
tags:
- k8s-reading
title: "Concepts - Storage - Volumes"
weight: 20
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/storage/volumes/)

## 為什麼需要 Volume？

預設情況下，容器內的檔案系統是**短暫的 (Ephemeral)**。當容器崩潰並被 `kubelet` 重啟時，所有檔案都會遺失。此外，在一個擁有多个容器的 Pod 中，容器之間也無法直接共享檔案。

為了解決這些問題，Kubernetes 引入了 **Volume (儲存卷)** 的概念。Volume 是一個可以被掛載到 Pod 中一個或多個容器的目錄，它的生命週期獨立於容器。

K8s 的 Volume 抽象模型非常強大，它支援多種類型，可以滿足各種不同的儲存需求。我們可以將其大致分為兩大類：

1.  **非持久性 Volume**：生命週期與 Pod 相同。當 Pod 被刪除時，Volume 的內容也會隨之消失。
2.  **持久性 Volume**：生命週期獨立於 Pod。即使 Pod 被刪除，Volume 的內容依然存在。

本篇文章將聚焦於幾種最常用的**非持久性 Volume**。

## Volume 的掛載流程

在 K8s 中，使用 Volume 分為兩步：
1.  在 Pod 層級的 `.spec.volumes` 中定義一個 Volume，並給它一個名字。
2.  在容器層級的 `.spec.containers.volumeMounts` 中，透過名字引用上面定義的 Volume，並指定要將它掛載到容器內的哪個路徑 (`mountPath`)。

```mermaid
graph TD
    subgraph Pod Spec
        direction LR
        A["`.spec.volumes` <br> (定義 Volume)"]
        B["`.spec.containers.volumeMounts` <br> (掛載 Volume)"]
    end
    
    A -- "透過 name 引用" --> B
```

## 常用的非持久性 Volume 類型

| Volume 類型 | 核心用途 | 範例 |
| :--- | :--- | :--- |
| **`emptyDir`** | Pod 內**容器之間的臨時共享空間**。 | 一個容器寫入資料，另一個 Sidecar 容器讀取並處理。 |
| **`configMap`** | 將 [ConfigMap](/docs/k8s-doc-reading/20250703_k8s-doc-reading-configuration-configmaps/) 物件的內容以**檔案形式**掛載到容器中。 | 將 `nginx.conf` 設定檔注入到 NGINX 容器中。 |
| **`secret`** | 將 [Secret](/docs/k8s-doc-reading/20250703_k8s-doc-reading-configuration-secrets/) 物件的內容以**檔案形式**掛載到容器中。 | 將 TLS 憑證和私鑰掛載到 Ingress Controller 中。 |
| **`hostPath`** | 將**節點 (Node)** 的檔案系統上的檔案或目錄掛載到容器中。 | 日誌收集代理 (DaemonSet) 需要讀取節點上的 `/var/log` 目錄。 |
| **`downwardAPI`**| 將 Pod 自身的**元數據** (如名稱、標籤、註解) 以檔案形式暴露給容器內部。 | 應用程式需要知道自己正在哪個 Namespace 或哪個 Node 上運行。 |

### `emptyDir` 範例
一個 `emptyDir` Volume 在 Pod 被分配到節點時首次建立，只要該 Pod 在該節點上運行，該 Volume 就會一直存在。當 Pod 因任何原因從節點上移除時，`emptyDir` 中的資料將被永久刪除。

### `configMap` / `secret` 範例
這是將設定與應用程式分離的最佳實踐。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
spec:
  containers:
    - name: test
      image: busybox:1.28
      command: ['sh', '-c', 'cat /etc/config/log_level']
      volumeMounts:
        - name: config-volume # 引用下面定義的 Volume
          mountPath: /etc/config # 掛載到容器的路徑
  volumes:
    - name: config-volume # 定義一個名為 config-volume 的 Volume
      configMap:
        name: log-config # 指定來源是名為 log-config 的 ConfigMap
        items:
          - key: log_level # 指定要掛載的 key
            path: log_level.conf # 掛載後的檔名
```

### `hostPath` 的注意事項
`hostPath` 是一個強大但危險的功能，它打破了容器的隔離性。
-   **安全風險**：如果容器能夠存取到節點的敏感檔案（如 Docker socket），可能會導致容器逃逸。
-   **可攜性差**：應用程式的運行將依賴於特定節點上的特定檔案結構。
因此，除非您正在開發需要存取節點資訊的系統級應用（如 CNI 插件、監控代理），否則應**極力避免**使用 `hostPath`。

## 邁向持久化儲存
以上介紹的 Volume 類型，其生命週期都與 Pod 綁定。當我們需要處理像資料庫這樣、資料必須在 Pod 重啟甚至刪除後依然存在的場景時，就需要進入**持久化儲存 (Persistent Storage)** 的世界了。

在下一篇文章中，我們將深入探討 K8s 如何透過 `PersistentVolume` (PV)、`PersistentVolumeClaim` (PVC) 和 `StorageClass` (SC) 這一套精巧的機制，來實現與儲存後端的解耦和動態配置。

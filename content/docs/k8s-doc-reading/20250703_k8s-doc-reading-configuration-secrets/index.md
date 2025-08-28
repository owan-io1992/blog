---
date: 2025-07-03T07:30:00
draft: false
tags:
- k8s-reading
title: "Concepts - configuration - secret"
weight: 23
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/configuration/secret/)

## 什麼是 Secret？

**Secret** 是 Kubernetes (K8s) 中用來儲存少量敏感資訊的物件，例如密碼、OAuth 權杖或 SSH 金鑰。在使用上，它與 [ConfigMap](@/docs/k8s-doc-reading/20250703_k8s-doc-reading-configuration-configmaps/index.md) 非常相似，可以透過環境變數或掛載成檔案的方式注入到 Pod 中。

### 重要：原生 Secret 並未加密

在開始之前，必須強調一個非常重要的觀念：**根據預設，K8s 中的 Secret 物件是以未加密的 Base64 編碼形式儲存在 etcd 中。**

Base64 編碼只是一種資料表示方式，**完全不具備加密效果**。這意味著任何能夠存取 etcd 的人，都可以輕易地解碼並讀取其中的敏感資訊。

### 那為什麼還要用 Secret？

既然 Secret 預設不加密，為什麼不直接用 ConfigMap 就好？這是一個很好的問題，原因如下：

1.  **語意上的分離**：將敏感資訊（如密碼）和非敏感設定（如環境變數）明確區分開來，是一種良好的維運實踐。
2.  **更嚴格的權限控管**：您可以透過 RBAC (Role-Based Access Control) 為 Secret 設定比 ConfigMap 更嚴格的存取權限，限制特定使用者或服務帳號對其的讀取。
3.  **生態系整合**：K8s 生態系中的許多工具都是圍繞 Secret 物件進行整合的。例如，憑證管理工具 `cert-manager` 會自動將申請到的 TLS 憑證儲存為 Secret；外部密鑰管理系統（如 HashiCorp Vault）也透過整合 Secret 來向應用程式提供金鑰。
4.  **內建的特定類型**：Secret 提供了特定的 `type`，用於驗證和處理特定格式的敏感資料，例如 Docker Registry 的認證資訊或 TLS 憑證。

## Secret 的類型 (Types)

與通用的 ConfigMap 不同，Secret 提供了 `type` 欄位，讓 K8s 能夠驗證其內容格式是否正確。以下是幾種最常用的類型：

| 類型 (Type) | 描述 | 常見用途 |
| :--- | :--- | :--- |
| `Opaque` | 預設類型，不對內容格式做任何驗證，以 key-value 形式儲存任意資料。 | 儲存資料庫密碼、API 金鑰等。 |
| `kubernetes.io/dockerconfigjson` | 用於儲存私有 Docker Registry 的認證資訊。 | 在 Pod 中設定 `imagePullSecrets`，以便拉取私有映像檔。 |
| `kubernetes.io/tls` | 用於儲存 TLS 憑證和私鑰。 | 供 Ingress Controller 使用，以啟用 HTTPS。 |

更多類型可以參考[官方文件](https://kubernetes.io/docs/concepts/configuration/secret/#secret-types)。

## 如何使用 Secret？

使用 Secret 的流程分為兩步：**建立 Secret 物件** 和 **在 Pod 中使用它**。

### 1. 建立 Secret

以下是一個 `Opaque` 類型的 Secret 範例。請注意，`data` 欄位中的值必須是 Base64 編碼過的。

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  # echo -n 'admin' | base64  => YWRtaW4=
  username: YWRtaW4=
  # echo -n 'p@ssw0rd123' | base64 => cEBzc3cwcmQxMjM=
  password: cEBzc3cwcmQxMjM=
```

> **小技巧**：如果您不想手動進行 Base64 編碼，可以使用 `stringData` 欄位。K8s 會在建立 Secret 時自動為您編碼。
>
> ```yaml
> apiVersion: v1
> kind: Secret
> metadata:
>   name: my-secret
> type: Opaque
> stringData:
>   username: admin
>   password: p@ssw0rd123
> ```

### 2. 在 Pod 中使用 Secret

與 ConfigMap 一樣，您可以將 Secret 作為**環境變數**或**掛載的檔案**注入到容器中。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-test-pod
spec:
  containers:
    - name: test-container
      image: registry.k8s.io/busybox:1.27.2
      command: [ "/bin/sh", "-c", "env && cat /etc/secret-volume/password" ]
      
      # 將 Secret 的特定 key 注入為環境變數
      env:
        - name: SECRET_USERNAME
          valueFrom:
            secretKeyRef:
              name: my-secret
              key: username

      # 將整個 Secret 掛載為一個目錄下的檔案
      volumeMounts:
      - name: secret-volume
        mountPath: "/etc/secret-volume"
        readOnly: true
  volumes:
    - name: secret-volume
      secret:
        secretName: my-secret
```

## 整合外部密鑰管理系統

對於生產環境，強烈建議不要將敏感資訊直接儲存在 K8s 的 etcd 中。更安全的做法是使用專業的外部密鑰管理系統（KMS），例如：

-   HashiCorp Vault
-   AWS Secrets Manager
-   Azure Key Vault
-   Google Secret Manager

K8s 提供了 [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)，它允許您將這些外部系統中的機密資訊以磁碟區 (Volume) 的形式掛載到 Pod 中，而無需將它們實際儲存在 K8s 內。

這種方式將密鑰管理的生命週期與 K8s 分離，提供了更高級別的安全性、集中管理和稽核能力。由於整合過程涉及較多組件，我們將在後續的文章中專門介紹。
---
date: 2025-06-27T11:53:00  
draft: false
tags:
- k8s-reading
title: "Concepts: Getting started - helm"
weight: 7
---
![alt](images/banner.png)  

<!--more-->

## 為什麼需要 Helm？

在前面的章節中，我們學會了使用 `kubectl apply -f` 來部署 Kubernetes (K8s) 的 YAML 設定檔。對於單一的應用程式，這或許還能應付。但想像一下，一個完整的應用程式可能包含：
-   一個 `Deployment`
-   一個 `Service`
-   一個 `Ingress`
-   一個 `ConfigMap`
-   可能還有 `Secret`, `ServiceAccount`, `PersistentVolumeClaim`...

當您需要在不同環境（開發、測試、生產）部署這套應用，或是要將您的應用分享給他人時，手動管理這一大堆 YAML 檔案會變成一場災難。

**Helm** 就是為了解決這個問題而誕生的。它被譽為「**The package manager for Kubernetes**」，是 K8s 世界的 `apt`、`yum` 或 `Homebrew`。

## Helm 核心概念解析：食譜的比喻

要理解 Helm，我們可以把它比喻成「照著食譜做菜」：

| Helm 概念 | 食譜比喻 | 角色 |
| :--- | :--- | :--- |
| **Chart** | 食譜 | 一份預先打包好的部署方案，它定義了安裝一個應用程式（例如 WordPress）所需的所有 K8s 物件（Deployment, Service 等）的**模板**。 |
| **`values.yaml`** | 客製化選項 | 食譜上提供的客製化選項。例如，「辣度：可選微辣、中辣、大辣」。使用者可以透過修改這些值，來調整最終部署的細節，而無需修改複雜的食譜本身。 |
| **Release** | 菜餚 | 根據一份 Chart (食譜) 和您指定的 `values` (客製化選項)，在您的 K8s 叢集上建立的一個**實際運行的應用實例**。 |
| **Repository**| 食譜倉庫 | 一個集中的地方，用來存放和分享各種 Charts (食譜)。 |

Helm 的核心價值在於其**模板化 (Templating)** 與**可配置性 (Configurability)**。它讓複雜的 K8s 應用部署，變得像安裝一個軟體套件一樣簡單。

## 實戰：三步驟部署你的第一個應用

讓我們來實際操作一次，使用 Helm 在 K8s 上部署一個 NGINX 網站。

### 步驟 1：加入 Chart 倉庫 (Repository)
首先，我們需要告訴 Helm 去哪裡找「食譜」。[Bitnami](https://bitnami.com/stacks/helm) 維護了一個非常流行的高品質 Chart 倉庫。
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 步驟 2：搜尋並檢查 Chart
我們可以搜尋看看這個倉庫裡有沒有 NGINX 的 Chart。
```bash
$ helm search repo nginx
NAME             	CHART VERSION	APP VERSION	DESCRIPTION
bitnami/nginx    	20.0.7       	1.28.0     	NGINX Open Source is a web server that can be a...
...
```
我們找到了 `bitnami/nginx`。在安裝之前，可以先用 `helm show values` 看看它提供了哪些「客製化選項」(`values.yaml`)。
```bash
helm show values bitnami/nginx
```
您會看到非常多的可配置項，例如 `replicaCount`, `service.type`, `ingress.enabled` 等。

### 步驟 3：安裝 Chart 並客製化
現在，我們來安裝這個 Chart，並建立一個名為 `my-nginx` 的 Release。同時，我們使用 `--set` 參數來**覆蓋**預設的 `values`，將服務類型改為 `NodePort`。

```bash
helm install my-nginx bitnami/nginx --set service.type=NodePort
```
安裝完成後，Helm 會輸出一些有用的資訊，告訴您如何存取這個 NGINX 服務。您也可以透過 `kubectl get all` 來查看 Helm 為您建立的所有 K8s 物件。

**管理您的 Release：**
```bash
# 列出所有已安裝的 Release
helm list

# 升級 Release (例如，開啟 Ingress)
helm upgrade my-nginx bitnami/nginx --set ingress.enabled=true

# 卸載 Release (會刪除所有相關的 K8s 物件)
helm uninstall my-nginx
```

## 深入 Chart 結構

一個 Helm Chart 本質上是一個特定結構的目錄。您可以透過 `helm pull --untar` 指令下載任何 Chart 的原始碼來一探究竟。

```bash
helm pull bitnami/nginx --untar
cd nginx
tree .
```

其中，最重要的三個部分是：

-   `Chart.yaml`: 包含了 Chart 的元數據，例如名稱、版本、描述等。
-   `values.yaml`: **客製化核心**。定義了所有可供使用者調整的預設變數。
-   `templates/`: **模板核心**。存放了所有 K8s 物件的 YAML 模板檔案。這些檔案使用 Go 模板語法，並會在部署時，將 `values.yaml` 中的值渲染進去，最終生成標準的 K8s YAML。

## Helm vs. Kustomize

另一個常見的 K8s 設定管理工具是 [Kustomize](https://kustomize.io/)，它也被整合進了 `kubectl` 中。兩者的哲學不同：

-   **Helm**：**模板化**。它像一個程式語言，有變數、有函式、有邏輯控制。功能強大，但學習曲線稍高。
-   **Kustomize**：**疊加式 (Overlay)**。它透過對基礎 YAML 進行「打補丁 (Patch)」的方式來產生不同環境的設定，侵入性小，更貼近原生 YAML。

兩者各有優劣，但目前 Helm 憑藉其豐富的社群生態和強大的打包能力，在「應用程式分發」領域仍佔據主流地位。

---
Helm 是 K8s 生態系中不可或- 缺的一環。學會使用 Helm，不僅能讓您輕鬆部署社群中成千上萬的開源應用，更能幫助您標準化、模組化地管理自己的應用程式，是每一位 K8s 使用者都應掌握的關鍵技能。
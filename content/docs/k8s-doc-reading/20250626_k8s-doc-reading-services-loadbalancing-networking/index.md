---
date: 2025-06-26T04:41:00
draft: false
tags:
- k8s-reading
title: "Concepts - Services, Load Balancing, and Networking"
weight: 14
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/services-networking/)   

在 Kubernetes 的世界裡，網路是一個至關重要的基礎設施。它確保了容器之間、Pod 之間以及外部世界與叢集之間的順暢通訊。這篇文章將深入探討 Kubernetes 網路的核心概念，包括 Services、Load Balancing 和更廣泛的 Networking 模型。

## Kubernetes 網路模型基礎

Kubernetes 對於任何網路實現都設定了幾個基本要求，以確保其一致性和可預測性：

- **每個 Pod 都有自己獨立的 IP 位址**：這就是所謂的 "IP-per-Pod" 模型。叢集中的所有 Pod 都位於一個共享的、可路由的網路空間中，這個網路通常被稱為 Pod 網路或叢集網路。
- **Pod 之間可以直接通訊**：無論 Pod 是否在同一個節點 (Node) 上，它們都可以使用對方的 IP 位址直接進行通訊，無需網路位址轉換 (NAT)。
- **容器間的通訊**：如果一個 Pod 中有多個容器，它們共享同一個網路命名空間 (network namespace)，這意味著它們可以使用 `localhost` 互相通訊，並且共享同一個 Pod IP 位址和埠口空間。因此，同一個 Pod 內的容器不能使用相同的埠口。

這個網路模型主要是透過 **Container Networking Interface (CNI)** 的插件來實現的。CNI 是一個標準，定義了容器執行環境 (如 kubelet) 與網路插件之間的介面。常見的 CNI 插件包括 Calico, Flannel, Cilium, 和 Weave Net 等。

## Service: 叢集內部的抽象化與負載平衡

當 Pod 因為重啟、擴縮容 (scaling) 或節點故障而來來去去時，它們的 IP 位址會隨之改變。這使得直接依賴 Pod IP 的通訊方式變得不可靠。**Service** 正是為了解決這個問題而誕生的。

Service 為一組功能相同的 Pod 提供了一個穩定、單一的存取點。它擁有一個固定的虛擬 IP (稱為 **ClusterIP**) 和一個 DNS 名稱，生命週期獨立於 Pod。當流量被送到 Service 的 ClusterIP 時，它會被自動地轉發到後端健康的 Pod 上，從而實現了服務發現 (service discovery) 和負-載平衡 (load balancing)。

這個轉發機制是由每個節點上的 **kube-proxy** 元件來實現的。

### Service 的類型

根據不同的暴露需求，Service 提供了幾種類型：

1.  **`ClusterIP`** (預設類型):
    -   為 Service 分配一個叢集內部的虛擬 IP。
    -   此 Service 只能在叢集內部被訪問，無法從外部直接存取。
    -   這是最常見的 Service 類型，適用於叢集內部的服務間通訊。

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: my-internal-service
    spec:
      selector:
        app: MyApp
      type: ClusterIP
      ports:
        - protocol: TCP
          port: 80
          targetPort: 9376
    ```

2.  **`NodePort`**:
    -   在 `ClusterIP` 的基礎上，會在叢集中的 **每一個節點** 上開放一個靜態的埠口（`NodePort`）。
    -   外部流量可以透過 `[NodeIP]:[NodePort]` 的方式訪問到這個 Service。
    -   Kubernetes 會自動將流量從 `NodePort` 路由到 Service 的 `ClusterIP`，再轉發到後端 Pod。
    -   主要用於開發或測試環境，方便臨時將服務暴露給外部。

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nodeport-service
    spec:
      selector:
        app: MyApp
      type: NodePort
      ports:
        - port: 80
          targetPort: 80
          # nodePort: 30007 # 可選，不填會自動分配
    ```

3.  **`LoadBalancer`**:
    -   這是 `NodePort` 和 `ClusterIP` 的擴展。
    -   當設定為此類型時，Kubernetes 會向底層的雲端供應商 (如 AWS, GCP, Azure) 請求一個外部的負載平衡器。
    -   雲端供應商會為此 Service 分配一個公開的、可路由的 IP 位址，並將流量導向到叢集的 `NodePort`。
    -   這是將服務標準化地暴露到網際網路上的最佳方式。如果不在雲端環境中，或環境不支援，此設定效果等同於 `NodePort`。

4.  **`ExternalName`**:
    -   這是一個特例，它不涉及任何代理或轉發。
    -   它將 Service 對應到一個外部的 DNS 名稱，而不是 `selector`。
    -   當叢集內的客戶端查詢這個 Service 時，會直接得到一個 CNAME 記錄，指向該外部 DNS 名稱。
    -   適用於將叢集內的服務指向一個外部的服務，例如外部的資料庫。

## Ingress & Gateway: 管理外部流量的進階路由

雖然 `NodePort` 和 `LoadBalancer` 可以將服務暴露給外部，但它們在功能上有所限制，通常只能做四層 (TCP/UDP) 的轉發。當我們需要更複雜的路由規則時，例如基於主機名稱 (virtual hosting) 或 URL 路徑的路由，就需要使用 **Ingress** 或 **Gateway API**。

-   **Ingress**: 是一個 API 物件，它定義了從叢集外部到內部 Service 的 HTTP 和 HTTPS 路由規則。Ingress 本身不執行任何操作，它需要一個 **Ingress Controller** 來實現這些規則。Ingress Controller 是一個獨立的 Pod，它會監聽 Ingress 資源的變化，並設定對應的負載平衡器（如 Nginx, HAProxy, Traefik）來處理流量。

-   **Gateway API**: 是 Ingress 的下一代演進，提供更強大、更靈活、角色分離的路由管理能力。它將路由配置分解為不同的角色（基礎設施管理員、叢集管理員、應用開發者），使得權責更加清晰。

## NetworkPolicy: 保護 Pod 的網路安全

在預設情況下，Kubernetes 叢集中的所有 Pod 之間都可以自由通訊。但在許多情況下，我們需要更精細的存取控制，例如，只允許前端 Pod 訪問後端 Pod，或只允許特定命名空間的 Pod 訪問資料庫。

**NetworkPolicy** 提供了這種基於網路策略的隔離能力。它允許你使用標籤選擇器 (label selector) 來定義哪些 Pod 可以互相通訊。

**重要提示**: NetworkPolicy 的實現也依賴於 CNI 插件。並非所有的 CNI 插件都支援 NetworkPolicy。例如，Flannel 預設不支援，但 Calico 和 Cilium 等則提供了強大的支援。

## Kubernetes 實作了哪些？

理解 Kubernetes 自身提供什麼，以及哪些需要依賴外部插件，是非常重要的：

-   Pod 網路 (Pod Network): ❌ Kubernetes 本身不提供，依賴 CNI 插件。
-   Service: ✅ Kubernetes 的核心功能。
    -   `ClusterIP`: ✅
    -   `NodePort`: ✅
    -   `LoadBalancer`: ⚠️ 需要雲端供應商或特定插件的整合。
    -   `ExternalName`: ✅
-   Ingress: ⚠️ Kubernetes 只提供 API 物件，需要額外安裝 Ingress Controller。
-   Gateway: ⚠️ 同 Ingress，只提供 API，需要額外安裝實現 Gateway API 的控制器。
-   NetworkPolicy: ⚠️ Kubernetes 只提供 API 物件，需要支援此功能的 CNI 插件。

---
以上是 Kubernetes 網路核心概念的詳細介紹。對於一個剛開始使用 k3s 的開發者來說，好消息是 k3s 預設已經為你打包好了大部分基礎設施：

-   **CNI**: 預設使用 Flannel，提供了開箱即用的 Pod 網路。
-   **Service Load Balancer**: k3s 內建了名為 Klipper 的控制器，它可以在沒有雲端供應商的環境中實現 `LoadBalancer` 類型的 Service。
-   **Ingress Controller**: 預設安裝了 Traefik 作為 Ingress Controller。

這意味著在 k3s 環境中，你可以直接使用 `LoadBalancer` 和 `Ingress`，而無需進行額外的安裝與設定。但如果你使用的是其他 Kubernetes 發行版（如 kubeadm），則可能需要手動安裝這些元件。

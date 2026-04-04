---
tags:
- k8s-reading
---
# Concepts - Services, Load Balancing, and Networking - Services
![alt](images/banner.png)  

[doc link](https://kubernetes.io/docs/concepts/services-networking/service/)

## 為什麼需要 Service？

在 Kubernetes (K8s) 中，每個 Pod 都有自己獨立的 IP 位址。然而，直接使用 Pod IP 進行通訊會遇到兩個致命問題：
1.  **不穩定**：Pod 是短暫的，當它被銷毀並重建後，會獲得一個全新的 IP 位址。
2.  **不具備負載平衡**：如果您有多個提供相同服務的 Pod 副本，您需要一個機制來將流量平均分配給它們。

**Service** 正是為了解決這兩個問題而誕生的。它為一組功能相同的 Pod 提供了一個**穩定、單一的虛擬存取入口**。

您可以將 Service 想像成一個團隊的「總機號碼」。您只需要撥打這個固定的總機號碼，後端的接線生 (`kube-proxy`) 就會自動幫您轉接到一位當前有空的客服人員 (Pod)。您完全不需要關心客服人員有多少位，或是他們的分機號碼是多少。

這個機制實現了 K8s 中兩個最重要的概念：
-   **服務發現 (Service Discovery)**：透過一個穩定的 DNS 名稱和虛擬 IP。
-   **負載平衡 (Load Balancing)**：自動將流量分配到後端健康的 Pod。

## Service 如何運作：Selector 與 Endpoints

Service 是如何知道要將流量轉發到哪些 Pod 的呢？答案是透過 **Labels** 和 **Selectors**。

1.  您為一組 Pod 加上特定的標籤，例如 `app: MyApp`。
2.  您建立一個 Service，並在其 `.spec.selector` 中指定它要尋找帶有 `app: MyApp` 標籤的 Pod。
3.  K8s 的 **EndpointSlice Controller** 會持續地監控符合此 selector 的 Pod。
4.  它會將所有**健康的、就緒的 (Ready)** Pod 的 IP 和埠號，記錄在一個名為 **EndpointSlice** 的物件中。
5.  每個節點上的 **`kube-proxy`** 會監聽 EndpointSlice 的變化，並據此更新節點上的 `iptables` 或 `IPVS` 規則，實現流量的轉發。

```mermaid
graph TD
    A[Service <br> `selector: app=MyApp`] -- "Watches for Pods with label" --> B((Pod <br> `app=MyApp`));
    A -- "Updates" --> C{EndpointSlice <br> `[Pod1_IP:Port, Pod2_IP:Port]`};
    D(kube-proxy on each Node) -- "Watches" --> C;
    D -- "Updates iptables/IPVS rules" --> E[Node's Network Rules];
```

## Service 的四種類型詳解

| 類型 | 作用域 | IP 來源 | 典型用途 |
| :--- | :--- | :--- | :--- |
| **`ClusterIP`** | **叢集內部** | 由 K8s 分配的虛擬 IP | **(預設)** 叢集內部的服務間通訊。 |
| **`NodePort`** | 叢集內部 + 節點 | 在每個節點上開啟一個靜態埠號 | 臨時暴露服務，用於開發或測試。 |
| **`LoadBalancer`** | **叢集外部** | 由雲端供應商提供的外部負載平衡器 IP | 將服務標準化地暴露到網際網路。 |
| **`ExternalName`** | 外部服務 | 一個外部的 DNS 名稱 | 在叢集內部用一個別名來代理一個外部服務。 |

### `ClusterIP` (預設)
最常見的類型，為 Service 分配一個只能在叢集內部存取的虛擬 IP。

### `NodePort`
在 `ClusterIP` 的基礎上，會在**所有**節點上開啟同一個埠號 (`30000`-`32767`)。外部流量可以透過 `[任何節點 IP]:[NodePort]` 來存取該服務。

### `LoadBalancer`
在 `NodePort` 的基礎上，會向雲端供應商（如果有的話）申請一個外部負載平衡器。雲端 LB 會將流量導向所有節點的 `NodePort`。這是將服務暴露給外部世界的標準方式。

### `ExternalName`
一個特例。它不使用 `selector`，而是直接將 Service 的 DNS 名稱，以 CNAME 的形式指向一個外部的 DNS 名稱。

## Headless Service：一種特殊的模式
當您將 Service 的 `.spec.clusterIP` 設為 `None` 時，就建立了一個 **Headless Service**。

-   **無 ClusterIP**：K8s 不會為它分配虛擬 IP，因此 `kube-proxy` 也不會處理它。
-   **直接解析到 Pod IP**：當您查詢一個 Headless Service 的 DNS 時，它不會回傳單一的 ClusterIP，而是會直接回傳**後端所有就緒 Pod 的 IP 位址列表**。

這種模式繞過了 K8s 的負載平衡，允許客戶端直接與每個 Pod 進行通訊。它對於需要自己進行服務發現和成員管理的有狀態應用（如資料庫叢集、ZooKeeper）至關重要，也是 **StatefulSet** 的必要前置條件。

---
Service 是 K8s 網路的基石，它將動態、脆弱的 Pod 抽象成穩定、可靠的服務，是構建微服務架構不可或缺的一環。

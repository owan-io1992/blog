---
date: 2025-07-04T03:09:00
draft: false
tags:
- k8s-reading
title: "Concepts - configuration - Resource Management for Pods and Containers"
weight: 25
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

## 為什麼需要資源管理？

在 Kubernetes (K8s) 中，適當的資源管理是維持叢集穩定和高效運作的基石。如果沒有為 Pod 設定資源，可能會發生以下情況：

-   **調度不均**：Scheduler (排程器) 無法得知 Pod 的資源需求，可能會將大量 Pod 塞到同一個 Node 上，導致該 Node 過載，而其他 Node 卻很空閒。
-   **資源搶佔**：某個 Pod 可能會無限制地消耗 CPU 或 Memory，導致同一 Node 上的其他重要 Pod 無法正常運作，甚至造成整個 Node 當機。
-   **核心服務不穩**：當 Node 資源耗盡時，K8s 會開始驅逐 (Evict) Pod 以回收資源。如果沒有妥善設定，您的核心應用程式可能會被優先驅逐。

因此，**強烈建議為所有在生產環境中運行的 Pod 設定資源**。

## 核心概念：Requests vs. Limits

K8s 透過兩個參數來管理容器的資源：`requests` 和 `limits`。

| 參數 | 餐廳比喻 | 作用 |
| :--- | :--- | :--- |
| **Requests** | 預約座位 | **用於 Pod 調度**：向 K8s **預約**資源。Scheduler 會確保 Node 上有足夠的「可分配資源」來滿足 Pod 的 `requests` 總和，才會將 Pod 調度到該 Node。 |
| **Limits** | 座位大小 | **用於資源限制**：設定 Pod 可使用的資源**天花板**。防止 Pod 無限制地佔用資源，影響到同一 Node 上的其他 Pod。 |

---

### `requests`：調度的入場券

-   `requests` 是 Scheduler 進行決策的主要依據。一個 Node 的可分配資源，就是其總容量減去所有已調度 Pod 的 `requests` 總和。
-   **重要**：`requests` **並非強制保留**。它只是一個調度時的承諾。如果一個 Pod 實際使用的資源少於其 `requests`，那麼 Node 上空閒出來的這部分資源可以被其他 Pod 使用。

### `limits`：資源使用的天花板

-   `limits` 是由 `kubelet` 強制執行的硬性限制。
-   **CPU**：如果容器嘗試使用超過 `limits.cpu` 的 CPU 資源，其使用量會被**節流 (Throttled)**，導致應用程式效能下降。
-   **Memory**：如果容器嘗試使用超過 `limits.memory` 的記憶體，它會被系統以 **OOMKilled (Out of Memory Killed)** 的方式終止並重啟。

### 規則與預設值

1.  `limits` 必須大於或等於 `requests`。
2.  如果只設定 `limits` 而未設定 `requests`，則 `requests` 會被自動設為與 `limits` 相同。
3.  如果只設定 `requests` 而未設定 `limits`，則 Pod 可以使用該 Node 上所有的可用資源，直到 Node 資源耗盡。**這是一種危險的設定，應盡量避免。**

## 資源單位詳解

| 資源 | 單位 | 範例 | 說明 |
| :--- | :--- | :--- | :--- |
| **CPU** | Cores | `1` (1 個核心) <br> `0.5` (半個核心) <br> `500m` (500 millicores) | `m` 代表 `millicore` (千分之一核心)。`1000m` 等於 `1` 個核心。`1m` 是最小單位。 |
| **Memory** | Bytes | `128974848` (bytes) <br> `129M` (megabytes) <br> `123Mi` (mebibytes) | 建議使用 2 的冪次方單位 (Ei, Pi, Ti, Gi, Mi, Ki) 以避免混淆。 |

> **注意**：在設定 Memory 時，請注意大小寫。`m` (milli) 和 `M` (Mega) 代表的數量級天差地遠。

## 服務品質 (QoS) 等級

K8s 會根據您為容器設定的 `requests` 和 `limits`，自動為 Pod 分配一個**服務品質 (Quality of Service, QoS)** 等級。這個等級決定了當 Node 資源不足時，哪個 Pod 會被優先驅逐。

| QoS 等級 | 設定條件 | 特性 | 驅逐順序 |
| :--- | :--- | :--- | :--- |
| **Guaranteed** | 所有容器都必須同時設定 `requests` 和 `limits`，且兩者的值**完全相等**。 | 擁有最高的優先級，資源得到完全保障。 | **最後**被驅逐 |
| **Burstable** | 至少有一個容器設定了 `requests`，但 `requests` 和 `limits` 的值**不相等**。 | 可以超額使用資源 (burst)，但資源不被完全保障。 | **第二**順位被驅逐 |
| **BestEffort**| 所有容器都**沒有**設定任何 `requests` 或 `limits`。 | 優先級最低，沒有任何資源保障。 | **最先**被驅逐 |

**這就是為什麼設定 `requests` 和 `limits` 如此重要**：透過將核心服務設定為 `Guaranteed`，您可以確保在極端情況下，它們會是最後被系統犧牲的對象，從而保障了服務的穩定性。

## 設定範例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-demo
spec:
  containers:
  - name: guaranteed-container
    image: my-app
    # QoS: Guaranteed (requests == limits)
    resources:
      requests:
        memory: "200Mi"
        cpu: "500m"
      limits:
        memory: "200Mi"
        cpu: "500m"
  - name: burstable-container
    image: my-app
    # QoS: Burstable (requests != limits)
    resources:
      requests:
        memory: "100Mi"
        cpu: "250m"
      limits:
        memory: "200Mi"
        cpu: "1"
```

在這個範例中，如果 Node 資源耗盡，K8s 會先驅逐 `burstable-container` 所在的 Pod（如果它是 `Burstable` 或 `BestEffort` 等級），而 `guaranteed-container` 所在的 Pod 則會受到保護。

---

總結來說，資源管理不僅是關於限制，更是關於**溝通**。透過 `requests` 和 `limits`，您向 K8s 清楚地傳達了應用程式的需求和容忍度，而 K8s 則根據這些資訊，為您做出最合理的調度與資源分配決策，共同維護整個叢集的健康與穩定。
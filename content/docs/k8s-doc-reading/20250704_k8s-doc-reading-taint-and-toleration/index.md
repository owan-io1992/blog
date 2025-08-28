---
date: 2025-07-04T13:32:00
draft: false
tags:
- k8s-reading
title: "Concepts - scheduling-eviction - Taints and Tolerations"
weight: 27
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

## Taints and Tolerations 是什麼？

在 Kubernetes (K8s) 的世界裡，調度 (Scheduling) 是一個核心議題。我們之前介紹過的 [Node Affinity](@/docs/k8s-doc-reading/20250704_k8s-doc-reading-assign_pod_to_node/index.md) 是一種「吸引」機制，讓 Pod 可以**選擇**被調度到特定的 Node 上。

而 **Taints (污點)** 和 **Tolerations (容忍)** 則是一種反向的「排斥」機制。

我們可以把它們想像成一個 VIP 休息室：

-   **Taint (污點)**：在 Node 的門口掛上一個「僅限 VIP 進入」的牌子。這個牌子會**排斥**所有非 VIP 的人。
-   **Toleration (容忍)**：Pod 身上帶著一張「VIP 通行證」。這張通行證讓它可以**容忍**門口的牌子，並順利進入。

簡單來說：
-   **Taint** 設定在 **Node** 上，用來排斥 Pod。
-   **Toleration** 設定在 **Pod** 上，用來容忍 Node 的 Taint。

只有當 Pod 的 Toleration 與 Node 的 Taint 相匹配時，這個 Pod 才能被調度到該 Node 上。

## 如何使用？

### 1. 為 Node 加上 Taint

您可以使用 `kubectl taint` 指令為 Node 加上或移除 Taint。一個 Taint 由三部分組成：`key=value:effect`。

`effect` 是 Taint 最重要的部分，它定義了排斥行為的嚴格程度：

| Effect | 描述 |
| :--- | :--- |
| `NoSchedule` | **不會**將新的 Pod 調度到這個 Node 上，但**不影響**已經在上面運行的 Pod。 |
| `PreferNoSchedule`| **盡量不要**將新的 Pod 調度到這個 Node 上。這是一個「軟性」的限制，如果叢集中沒有其他可用的 Node，Scheduler 仍然可能會使用這個 Node。 |
| `NoExecute` | **不會**將新的 Pod 調度到這個 Node 上，並且會**驅逐 (Evict)** 已經在上面運行的、無法容忍此 Taint 的 Pod。 |

**範例：**
```bash
# 為 node1 加上一個 Taint，效果是 NoSchedule
kubectl taint nodes node1 dedicated=gpu:NoSchedule

# 移除上面加上的 Taint
kubectl taint nodes node1 dedicated=gpu:NoSchedule-
```

### 2. 為 Pod 加上 Toleration

您可以在 Pod 的 spec 中定義 Tolerations，使其能夠被調度到帶有特定 Taint 的 Node 上。

Toleration 的設定需要與 Taint 的 `key`、`value` 和 `effect` 相對應。`operator` 則定義了匹配的邏輯。

| Operator | 描述 |
| :--- | :--- |
| `Equal`  | (預設) Toleration 的 `key`, `value`, `effect` 必須與 Taint **完全相等**。 |
| `Exists` | 只需要 Toleration 的 `key` 和 `effect` 與 Taint 匹配即可，**忽略 `value`**。 |

**範例：**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-gpu-pod
spec:
  containers:
  - name: cuda-container
    image: nvidia/cuda:11.0-base
  tolerations:
  # 這個 Toleration 匹配 key=dedicated, value=gpu, effect=NoSchedule 的 Taint
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
```
這個 `my-gpu-pod` 因為擁有正確的 Toleration (VIP 通行證)，所以可以被調度到我們剛剛設定的 `node1` (VIP 休息室) 上。而其他沒有此 Toleration 的 Pod 則會被 `node1` 排斥。

### `NoExecute` 的特別之處

當 Node 被加上 `NoExecute` Taint 時，K8s 會立刻檢查該 Node 上所有運行的 Pod。對於沒有對應 Toleration 的 Pod，會立即將其驅逐。

對於擁有對應 Toleration 的 Pod，您可以額外設定 `tolerationSeconds`，讓 Pod 在被驅逐前有一段緩衝時間。

```yaml
tolerations:
- key: "node.kubernetes.io/unreachable"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 300
```
這個設定意味著：當此 Pod 所在的 Node 變得 `unreachable` (失聯) 時，Pod 會繼續在該 Node 上運行 300 秒。如果 300 秒後 Node 仍未恢復，K8s 就會將此 Pod 驅逐，並嘗試在其他健康的 Node 上重建它。

## 常見應用場景

1.  **專用節點 (Dedicated Nodes)**：
    這是最常見的用途。您可以為一組需要特殊硬體（如 GPU）或有特殊需求的應用程式（如 CI/CD build jobs）準備專用的 Node。透過為這些 Node 加上 Taint，並只為對應的 Pod 加上 Toleration，可以確保這些 Node 不會被其他無關的應用程式佔用。

2.  **隔離控制平面 (Control Plane Isolation)**：
    在一個標準的 K8s 叢集中，Control Plane 節點預設會被加上 Taint，以防止使用者應用程式被調度上去，從而保障叢集核心組件的穩定性。

3.  **基於節點狀況的驅逐 (Taint based Evictions)**：
    K8s Controller Manager 會自動為符合特定條件的 Node 加上 Taint。例如，當 Node 失聯時，會被加上 `node.kubernetes.io/unreachable` Taint；當 Node 記憶體壓力過大時，會被加上 `node.kubernetes.io/memory-pressure` Taint。這些 Taint 預設的 `effect` 都是 `NoExecute`，用來觸發自動驅逐機制，以維護應用的高可用性。

---

總結來說，Taints 和 Tolerations 提供了一種強大的機制，讓叢集管理者可以更精細地控制 Pod 的調度策略，將特定的工作負載引導到合適的 Node 上，或將其從不合適的 Node 上排斥出去。
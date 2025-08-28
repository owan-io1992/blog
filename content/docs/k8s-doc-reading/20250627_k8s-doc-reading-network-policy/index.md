---
date: 2025-06-28T10:40:00
draft: false
tags:
- k8s-reading
title: "Concepts - Services, Load Balancing, and Networking - networking policy"
weight: 18
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

## 為什麼需要網路策略？

在預設的 Kubernetes (K8s) 叢集中，網路是「**完全開放**」的。這意味著任何一個 Pod 都可以與任何其他 Pod 進行通訊，無論它們是否在同一個 Namespace。這種「預設允許 (Default Allow)」的模式雖然簡化了初始設定，但在生產環境中卻帶來了嚴重的安全隱憂。

**NetworkPolicy** 就像是 K8s 中的**虛擬防火牆**。它允許您基於標籤 (Labels) 和 IP 位址，精細地定義 Pod 之間的網路流量規則，從而實現「零信任 (Zero Trust)」的網路安全模型。

> **重要前提**：NetworkPolicy 的實現**完全依賴 CNI (Container Network Interface) 插件**。您必須使用支援 NetworkPolicy 的 CNI 插件（如 Calico, Cilium, Weave Net），這些策略才會生效。k3s 預設使用 Flannel，需要額外設定才能支援 NetworkPolicy。

## NetworkPolicy 的運作核心

NetworkPolicy 的運作基於一個核心原則：**一旦一個 Pod 被任何一個 NetworkPolicy 的 `podSelector` 選中，它就會進入「預設拒絕 (Default Deny)」模式。**

這意味著：
1.  **對於 Ingress (傳入流量)**：該 Pod 會拒絕**所有**傳入的流量，除非被某條 `ingress` 規則明確允許。
2.  **對於 Egress (傳出流量)**：該 Pod 會拒絕**所有**傳出的流量，除非被某條 `egress` 規則明確允許。

如果一個 Pod **沒有**被任何 NetworkPolicy 選中，那麼它將維持預設的「完全開放」狀態。

## 實戰演練：三種常見的隔離策略

### 策略一：預設隔離整個 Namespace
這是最常見的第一步，先將整個 Namespace 的所有 Pod 完全隔離，然後再逐一開放必要的流量。
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: my-app
spec:
  podSelector: {} # 一個空的 podSelector 會選中該 namespace 下的所有 Pod
  policyTypes:
  - Ingress
  - Egress
  # 沒有定義任何 ingress 或 egress 規則，意味著拒絕所有進出流量
```
> 這個策略就像是為 `my-app` 這個社區蓋起了高牆，禁止任何人車進出。

### 策略二：只允許特定 Namespace 的流量
假設我們希望 `my-app` 裡的 Pod 只能接收來自 `monitoring` Namespace 的流量。
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-monitoring
  namespace: my-app
spec:
  podSelector: {} # 應用到 my-app Namespace 的所有 Pod
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector: # 允許來源
        matchLabels:
          # 這裡的 label 應該是 monitoring namespace 自身的標籤
          kubernetes.io/metadata.name: monitoring
```
> 這就像是給監控中心（`monitoring`）的車輛發放了進入 `my-app` 社區的特別通行證。

### 策略三：只允許特定 App 之間的通訊
這是最精細的控制，例如，只允許 `frontend` Pod 訪問 `backend` Pod 的 `6379` 埠號。

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: my-app
spec:
  podSelector:
    matchLabels:
      app: backend # 此策略應用於所有帶有 app: backend 標籤的 Pod
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: # 只允許來自帶有 app: frontend 標籤的 Pod
        matchLabels:
          app: frontend
    ports: # 且只能訪問 6379/TCP 埠號
    - protocol: TCP
      port: 6379
```
> 這就像是規定只有「送餐車 (`frontend`)」才能進入「餐廳廚房 (`backend`)」，並且只能走「送餐專用通道 (port 6379)」。

## `to` 和 `from` 的邏輯：OR 與 AND

在 `ingress.from` 或 `egress.to` 規則中：
-   **不同 `-` 之間的規則是「OR」的關係**：只要滿足其中**任一**條件即可。
-   **同一個 `-` 下的規則是「AND」的關係**：必須**同時滿足**所有條件。

**OR 範例**：允許來自 `user: alice` 的 Namespace **或者** 來自 `role: client` 的 Pod。
```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        user: alice
  - podSelector:
      matchLabels:
        role: client
```

**AND 範例**：只允許來自 `user: alice` Namespace **並且** 帶有 `role: client` 標籤的 Pod。
```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        user: alice
    podSelector:
      matchLabels:
        role: client
```

## 注意事項與限制
-   **L4 層級**：NetworkPolicy 主要工作在 OSI 模型的第三層（IP）和第四層（TCP/UDP），它無法理解七層的 HTTP/gRPC 協議內容。
-   **CNI 依賴**：再次強調，策略能否生效，完全取決於您使用的 CNI 插件。
-   **延遲生效**：策略的下發和生效需要時間，在策略剛建立的短時間內，可能存在流量未被阻擋的空窗期。

---
NetworkPolicy 是實踐 K8s 零信任網路、保護叢集內部東西向流量的關鍵工具。雖然它只能做到 L3/L4 的控制，但對於大部分應用場景來說，已經提供了足夠強大的基礎安全保障。對於更複雜的七層策略，則需要借助 Service Mesh (如 Istio, Linkerd) 等工具來實現。
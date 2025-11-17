---
date: 2025-11-17T05:11:00  
draft: false
tags: ["k8s"]
title: "k8s Reserve Compute Resources for System Daemons"
---

doc link: https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/  

在 k8s node 中的 resource 大概分成 4 部份  
![](https://kubernetes.io/images/docs/node-capacity.svg)  

這四個 resource 的用意為了避免 workload 消耗所有 resourece 導致 node crash  


其中兩個用於設定 system daemond 為  
`Kube Reserved`: 保留 resource 給 kubernetes system daemons, 比如 `kubelet`, `container runtime`
`System Reserved`: 保留 resource 給系統服務, 比如 `sshd`, `kernel`  
`Eviction Thresholds`: evict pod threshold  
`Allocatable`: Allocatable = Total Node Capacity − kube-reserved − system-reserved − Hard Eviction Thresholds

## kube Reserved, system Reserved
這兩個設定 default 都是 nil  
參考:  
[kube Reserved](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#:~:text=kubeReserved%0Amap%5Bstring%5Dstring)
[system Reserved](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#:~:text=systemReserved%0Amap%5Bstring%5Dstring)

這樣看起來感覺很怪, 明明是很重要的設定, 為什麼 default 是 nil 呢？  

> [!CAUTION]
> 原因是這兩個參數相當危險
> 由於 limit = reserved, 因此如果設定太低, 反而會導致核心元件 resource starved 造成 node 異常  


## Eviction Thresholds 
與前面兩個 `kube Reserved`, `system Reserved` 相比  
這個參數則是把 pod evict 出去  
因此可以避免 node crash  
default: memory.available: "100Mi" nodefs.available: "10%" nodefs.inodesFree: "5%" imagefs.available: "15%"  
參考: [evictionHard](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#:~:text=evictionHard%0Amap%5Bstring%5Dstring)  


下面讓 AI 說明一些疑問

> [!NOTE]
> evictionHard 是計算 resource request 還是 resource usage ?

`evictionHard`（硬性驅逐門檻）**是根據節點上的** **實際資源用量 (Resource Usage)** **來判斷是否觸發驅逐，而不是基於 Pod 的** **資源請求 (Resource Request)**。

### 資源請求 (Request) vs. 資源用量 (Usage)

| 項目 | **Resource Request (請求)** | **Resource Usage (用量)** |
| :--- | :--- | :--- |
| **定義** | Pod 保證獲得的資源量。| Pod **實際使用**的資源量。 |
| **用途** | **排程器 (Scheduler)** 根據請求量來決定 Pod 能否被排程到節點上。 | **Kubelet** 根據用量來監控和限制 Pod 的行為，並作為**驅逐**的依據。 |
| **驅逐關係** | **無直接關係**。 | **直接相關**。驅逐策略就是為了應對實際用量過高。 |

### `evictionHard` 的運作原理

`kubelet` 監控以下幾種實際的 **可用 (Available)** 資源指標，並將它們與 `evictionHard` 門檻進行比較：

| 資源類型 | 監控的實際指標 |
| :--- | :--- |
| **記憶體 (Memory)** | `memory.available` (節點上的**總可用記憶體**) |
| **節點檔案系統 (Nodefs)** | `nodefs.available` (節點檔案系統的**總可用空間**) |
| **映像檔檔案系統 (Imagefs)** | `imagefs.available` (容器映像檔儲存目錄的**總可用空間**) |
| **進程 ID (PID)** | `pid.available` (節點上的**總可用進程 ID 數**) |

當這些**實際的可用量**低於設定的 `evictionHard` 門檻時，`kubelet` 就會啟動驅逐。

**簡而言之：**

*   **`evictionHard` 是對** **實際** **資源消耗的緩衝保護。**
*   它確保無論 Pod 請求了多少資源，節點本身總會留有一定量的**實際可用資源**，避免因工作負載**實際使用量**的峰值而導致節點 OOM 或磁碟耗盡。


當文件說 **"By 'reserving' some memory via evictionHard setting"** 時，它主要指的是在**排程器**的層面進行資源預留。

*   `evictionHard` 的值（例如：`memory.available<500Mi`）會被加到 **`kube-reserved`** 和 **`system-reserved`** 之後，從 **`Total Node Capacity`** 中扣除，從而計算出 **`Node Allocatable`**。
*   **結果**：排程器在將 Pod 排程到這個節點時，會確保所有 Pod 的 **Request 總和** 不會超過這個**已經扣除了驅逐門檻的 `Allocatable`**。

在這個意義上，`evictionHard` 確實參與了對資源 **Request** 的約束，**間接**地「預留」了一部分資源不給排程器使用。

###  `evictionHard` 的「執行」意義 (實際監控層面)

儘管它參與了對 **Request** 總量的限制，但當我們討論**實際驅逐**動作時，**`kubelet` 仍然是監控實際的資源用量 (Usage)**。

*   **真正的目的**：`evictionHard` 的根本目的是**在運行時**，確保當節點的**實際可用資源**下降到一個危險水準時，能有一個及時的「保險絲」來清除 Pod。
*   **觸發依據**：如果節點上的 Pod 因為運行時的突發用量（例如 `Burstable` 或 `BestEffort` Pod 突發地使用了超出其 Request 的資源），導致**節點的實際可用記憶體**低於 500Mi（以你的例子），驅逐就會發生。

### 總結

文件的說法 **"reserving... via evictionHard"** 是從**保護**的角度來說的：

*   **保護 1 (靜態)**：防止 Pod 的 **Request 總和** 超過安全的 **Allocatable** 範圍，這是對 **Request** 的限制。
*   **保護 2 (動態)**：當運行時 **Usage** 衝破安全線時，立即啟動驅逐機制，這是對 **Usage** 的監控。

因此，準確的理解是：**`evictionHard` 的值**既用於**限制排程器對 Request 總量的計算**（保護系統不被過度排程），也用於**作為 `kubelet` 監控實際 Usage 的門檻**（保護系統在運行時的穩定）。

**結論**：
**驅逐動作**的觸發是基於**實際資源用量 (Usage)**。

> [!NOTE]
> 與 evictionSoft 差異在那？

`evictionSoft`（軟性驅逐門檻）和 `evictionHard`（硬性驅逐門檻）是 `kubelet` 驅逐機制中的兩個主要類型，它們的主要差異在於**驅逐的緊迫性、是否需要寬限期**，以及**是否影響 Node Allocatable 的計算**。

以下是兩者差異的詳細比較：

---

### `evictionHard` vs. `evictionSoft` 比較

| 特性 | **`evictionHard` (硬性驅逐)** | **`evictionSoft` (軟性驅逐)** |
| :--- | :--- | :--- |
| **緊迫性** | **極高** (緊急情況) | **中等** (非緊急，有緩衝時間) |
| **觸發依據** | 資源**實際可用量**低於門檻。 | 資源**實際可用量**低於門檻。 |
| **寬限期 (`grace period`)** | **無** (`0`)。一旦觸發，立即行動。 | **必須指定** (`--eviction-soft-grace-period`)。只有持續時間超過寬限期才驅逐。 |
| **驅逐行為** | 立即嘗試終止 (Terminate) Pod，不允許有緩衝時間。 | 允許 Pod 有一個正常的終止流程（例如：執行 `preStop` Hook）。 |
| **Node Allocatable 影響** | **會**影響。其值會從總容量中扣除，計算 Allocatable。 | **不會**影響。它只是一個運行時監控指標，不影響排程計算。 |
| **必要性** | 節點健康和穩定性的**核心保障**，建議總是設定。 | 可選，用於在節點進入緊急狀態前優雅地清理資源。 |

---

### 詳細解釋

#### 1. `evictionHard` (硬性驅逐)

*   **功能**：節點的**生命維持機制**。
*   **如何運作**：`kubelet` 持續監控。一旦實際可用資源（例如 `memory.available`）**立即**跌破硬性門檻（例如 `500Mi`），`kubelet` 會**立即**執行驅逐，不給予任何寬限期。
*   **目的**：防止節點資源耗盡（OOM、磁碟爆滿），是**預留緩衝空間**以確保系統守護進程能穩定運作。

#### 2. `evictionSoft` (軟性驅逐)

*   **功能**：**優雅的資源回收機制**。
*   **如何運作**：
    1.  設定軟性門檻（例如：`memory.available<1Gi`）。
    2.  設定一個**寬限期**（`--eviction-soft-grace-period`，例如 `5m` 五分鐘）。
    3.  `kubelet` 監控到資源實際可用量低於 `1Gi` 時，會開始計時。
    4.  如果資源短缺的狀態**持續超過**這個五分鐘的寬限期，`kubelet` 才會啟動驅逐。
*   **目的**：
    *   **避免波動觸發**：防止短暫的資源峰值就導致 Pod 被驅逐。
    *   **優雅退出**：給予 Pod 寬裕的時間來執行正常的關閉流程（例如：儲存狀態）。
*   **注意事項**：因為它不影響 `Node Allocatable`，所以**它不會在排程層面預留資源**。它只是一個運行時的驅逐策略。

### 結論：

`evictionHard` 是一個**緊急且立即**的機制，主要目的是**保護系統**；它也是一個**排程參數**。

`evictionSoft` 是一個**緩慢且寬容**的機制，主要目的是**優雅地釋放資源**；它只是一個**運行時策略**。


## Allocatable 
最後的 Allocatable  
就是 pod 設定的 resource 設定了, 其給予空間給 spec.resources.requests 定義 pod 要 allocate 多少 resource  
細節可見  
[manage-resources-containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
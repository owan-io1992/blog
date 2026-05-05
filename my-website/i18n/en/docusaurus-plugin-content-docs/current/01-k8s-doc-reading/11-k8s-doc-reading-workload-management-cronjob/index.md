---
tags:
- k8s-reading
---
# Concepts - Workload Management - CronJob
![alt](images/banner.png)  

[doc link](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

## 什麼是 CronJob？

如果您熟悉 Linux 系統的 `crontab`，那麼您對 Kubernetes (K8s) 的 **CronJob** 就不會感到陌生。它的核心功能完全相同：**在指定的時間排程上，週期性地執行一個任務**。

在 K8s 的世界裡，CronJob 其實是在 [Job](/docs/k8s-doc-reading/k8s-doc-reading-workload-management-jobs/) 的基礎上，增加了一層「排程」的能力。它們的關係就像是「鬧鐘」：

-   **CronJob**：您設定的「**鬧鐘規則**」（例如：每天早上七點響）。
-   **Job**：當時鐘走到早上七點時，鬧鐘**實際響起的那一次動作**。CronJob Controller 會根據排程建立一個 Job 物件。
-   **Pod**：Job 建立的、負責執行實際任務的 Pod，也就是鬧鐘響起時播放的**鈴聲**。

CronJob 非常適合用來執行週期性的維護或管理任務，例如：
-   每日資料庫備份
-   每週產生數據報告
-   定期清理過期的快取資料

## CronJob 的核心設定

一個 CronJob 的 Manifest 主要由兩部分組成：排程 (`schedule`) 和 Job 模板 (`jobTemplate`)。

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-backup
spec:
  # 1. 排程 (Schedule)
  schedule: "0 5 * * *" # 使用標準的 Crontab 格式，表示每天早上 5:00 執行
  
  # 2. Job 模板 (Job Template)
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup-agent
            image: my-backup-tool
            args:
            - /bin/sh
            - -c
            - date; echo "Starting daily backup..."
          restartPolicy: OnFailure
          
  # 3. 其他重要設定
  concurrencyPolicy: Forbid
  startingDeadlineSeconds: 120
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
```

### 1. 排程 (`.spec.schedule`)
使用標準的 [Crontab](https://crontab.guru/) 格式來定義任務的執行週期。格式為：`分 時 日 月 週`。

### 2. Job 模板 (`.spec.jobTemplate`)
這部分定義了每次排程觸發時，要建立的 Job 物件的規格。其內容與一個獨立的 Job 物件的 `.spec` 完全相同。

### 3. 並行策略 (`.spec.concurrencyPolicy`)
這是一個非常重要的設定，它定義了當前一個任務尚未完成，下一個任務的排程時間又到了該如何處理。

```mermaid
graph TD
    subgraph "時間軸"
        T1(Job 1 開始) --> T2(Job 1 執行中...)
        T2 -- "排程時間到!" --> T3(Job 2 觸發)
        T3 --> T4(Job 1 仍在執行...)
    end
    
    subgraph "Concurrency Policy"
        A[Allow (預設)] --> A1{同時運行 Job 1 和 Job 2}
        B[Forbid] --> B1{跳過 Job 2，等待 Job 1 完成}
        C[Replace] --> C1{終止 Job 1，啟動 Job 2}
    end
```

-   **`Allow` (預設)**：允許並行運行多個 Job。
-   **`Forbid`**：如果前一個 Job 還在運行，則**跳過**本次的執行。
-   **`Replace`**：如果前一個 Job 還在運行，則會先**終止**舊的 Job，然後再啟動新的 Job。

對於備份這類不應並行執行的任務，通常會設定為 `Forbid`。

### 4. 其他重要設定

| 欄位 | 描述 | 預設值 |
| :--- | :--- | :--- |
| `startingDeadlineSeconds`| 如果 CronJob 因故錯過了排程時間，此欄位定義了可以「補做」這個任務的最大延遲秒數。超過此時間，該次執行就會被視為失敗。 | 未設定 |
| `successfulJobsHistoryLimit` | 保留多少個已成功 Job 的歷史紀錄。 | `3` |
| `failedJobsHistoryLimit` | 保留多少個已失敗 Job 的歷史紀錄。 | `1` |
| `timeZone` | 指定排程所使用的時區，例如 `Asia/Taipei`。 | Kube-controller-manager 的本地時區 |

## 重要注意事項
-   **冪等性**：您的定時任務應該被設計為**冪等的 (Idempotent)**，也就是說，重複執行多次和只執行一次的效果應該是相同的。這可以防止因 `concurrencyPolicy` 或其他原因導致的重複執行產生非預期的後果。
-   **資源消耗**：CronJob 會在指定時間建立 Job，而 Job 會建立 Pod。請確保您的叢集有足夠的資源來應對這些週期性的負載高峰。

---
CronJob 為 K8s 提供了強大的自動化排程能力，將傳統的 `crontab` 與雲原生的工作負載管理無縫結合，是實現自動化維運不可或缺的工具。
---
date: 2025-06-25T03:33:00
draft: false
tags:
- k8s-reading
title: "Concepts - Workload Management - Jobs"
weight: 11
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/workloads/controllers/job/)

## 什麼是 Job？

在 Kubernetes (K8s) 中，我們常用的 **Deployment** 或 **StatefulSet** 物件追求的是「**持續運行**」，它們會確保指定數量的 Pod 一直處於服務狀態。

而 **Job** 則完全不同，它追求的是「**最終完成**」。Job 會建立一個或多個 Pod，並確保其中指定數量的 Pod 能夠成功執行到結束 (Exit Code 0)。一旦達到預期的成功數量，Job 就會宣告完成，並且不會再建立新的 Pod。

Job 非常適合用來執行一次性或批次性的任務，例如：
-   資料庫遷移 (Database Migration)
-   批次資料處理與分析
-   備份或還原操作
-   CI/CD 流程中的建置或測試任務

> **重要**：在 Job 的 Pod 模板中，`spec.template.spec.restartPolicy` 只能設定為 `OnFailure` 或 `Never`，而不能是 `Always`（Deployment 的預設值）。這是因為 Job 的目標是「完成」，而不是「永遠運行」。

## Job 的三種運行模式

### 1. 非並行 Job (Non-parallel Job)
這是最簡單的模式。Job 只會啟動一個 Pod，並在該 Pod 成功結束後宣告完成。如果 Pod 失敗，Job 會根據 `restartPolicy` 和 `backoffLimit` 來決定是否重啟它。

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi-calculation
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: OnFailure # 或 Never
```

### 2. 固定完成次數的並行 Job (Parallel Job with a fixed completion count)
這是最常見的批次處理模式。您可以指定 Job 總共需要成功完成多少次 (`.spec.completions`)，以及最多可以同時運行多少個 Pod (`.spec.parallelism`)。

**應用場景**：假設您有 100 個影片需要轉檔。您可以設定 `completions: 100` 和 `parallelism: 10`，這樣 K8s 就會以 10 個 Pod 並行處理，直到 100 個影片都轉檔成功為止。

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: video-processing
spec:
  completions: 100 # 期望成功完成 100 次
  parallelism: 10  # 最多同時運行 10 個 Pod
  template:
    spec:
      containers:
      - name: processor
        image: my-video-processor
      restartPolicy: OnFailure
```

### 3. 工作佇列模式的並行 Job (Parallel Job with a work queue)
在這種模式下，您不設定 `.spec.completions`，只設定 `.spec.parallelism`。Job 會持續運行指定數量的並行 Pod，直到其中任何一個 Pod 以成功狀態退出，Job 就會被視為完成。

**應用場景**：當您的 Pod 需要從一個外部的工作佇列（如 RabbitMQ, SQS）中拉取任務來處理時，就適合使用此模式。Pod 之間需要自行協調，確保同一個任務不會被重複處理。一旦某個 Pod 確認佇列已空並成功退出，整個 Job 就結束了。

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: message-queue-consumer
spec:
  # 不設定 completions
  parallelism: 5 # 啟動 5 個消費者
  template:
    spec:
      containers:
      - name: consumer
        image: my-mq-consumer
      restartPolicy: OnFailure
```

## 控制 Job 的行為

### 失敗重試 (`.spec.backoffLimit`)
如果 Job 中的 Pod 因故失敗（例如：程式 bug 或暫時性網路問題），Job Controller 會在一段延遲後重新建立 Pod。這個延遲時間是**指數級增長**的（10s, 20s, 40s, ...），最長不超過 6 分鐘。

`.spec.backoffLimit` 參數定義了整個 Job 可以被標記為「失敗」的**重試次數上限**。一旦達到這個上限，Job 就會停止重試，並被標記為 `Failed`。預設值是 6。

```yaml
spec:
  backoffLimit: 4 # 最多重試 4 次
```

### Pod 失敗策略 (`.spec.podFailurePolicy`)
在某些情況下，您可能希望在特定錯誤發生時，立即讓 Job 失敗，而不要等到 `backoffLimit`。例如，當 Pod 因為節點映像檔問題而無法啟動時，重試是沒有意義的。

`podFailurePolicy` 允許您定義一組規則，當 Pod 的失敗符合這些規則時，Job 會立即終止。詳細用法請參考[官方文件](https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-failure-policy)。

### 成功策略 (`.spec.successPolicy`)
這是一個較新的功能，允許您在滿足特定條件時，提早宣告 Job 成功。例如，在一個並行 Job 中，只要有任意一個 Pod 成功，就可以終止所有其他 Pod 並宣告整個 Job 成功。詳細用法請參考[官方文件](https://kubernetes.io/docs/concepts/workloads/controllers/job/#success-policy)。

## 自動清理已完成的 Job

根據預設，Job 和其關聯的 Pod 在完成後會一直保留在叢集中，以便您查看日誌和狀態。這可能會佔用大量空間。

您可以設定 `.spec.ttlSecondsAfterFinished`，讓 Job Controller 在 Job 完成（無論成功或失敗）後的一段時間，自動將其刪除。

```yaml
spec:
  ttlSecondsAfterFinished: 100 # Job 完成 100 秒後自動刪除
```

---

Job 是 K8s 中處理非持續性任務的強大工具。在許多情況下，您可能會希望定期執行某個 Job，這時就需要 [CronJob](@/docs/k8s-doc-reading/20250625_k8s-doc-reading-workload-management-cronjob/index.md) 了，我們將在下一篇文章中介紹它。
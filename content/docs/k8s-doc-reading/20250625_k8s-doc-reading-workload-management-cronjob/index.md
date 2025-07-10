---
date: 2025-06-25T04:54:00
draft: false
tags:
- k8s-reading
title: "k8s doc reading: Concepts - Workload Management - CronJob"
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)   

對於熟悉 linux 的人, 基本上都熟悉 CronJob  
是的 k8s 的 CronJob 就是那個 CronJob  
關於 job 就是執行一次的工作  
關於 CronJob 就是週期性的工作   

sample manifest  
```bash
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "* * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox:1.28
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure
```

`.spec.schedule` 就是 linux 中指定 cronjob 的時間  
用法都一樣  
這個 sample 就是每分鐘都執行 pod  

要注意的是 這邊 `.sepc` 下是先是指定 jobTemplate  
也就是使用 job 的語法  
換句話說 cronjob 就是先產生 job, 透過 job 執行 pod  

## Deadline for delayed Job start
pod 可能會因為 resource 不足或其他原因無法被執行  
可以加上 `.spec.startingDeadlineSeconds` 來告訴 k8s  
如果超過這時間尚未啟動 pod , 就不要執行了   

## Concurrency policy 
在某些作業  比如說備份  
會希望一次只能進行一個作業  
就可以使用 `.spec.concurrencyPolicy` 避免同時執行  
(如果 schedule interval 太短, 前份 job 尚未完成就可能發生並行的 job)  

選項有  
Allow (default): 允許多個 job  
Forbid: 如果前個 job 尚未完成, 暫停執行新的 job, 如果超過 `.spec.startingDeadlineSeconds` 就略過本次 job  
Replace: 停掉舊的 job 並執行新的 job  

## Jobs history limits 
cronjob 是新增 job 去執行, 並且會 auto cleanup  
可以透過設定修改保留的份數  

`.spec.successfulJobsHistoryLimit`: 保留最後成功的 job, default: 3
`.spec.failedJobsHistoryLimit`: 保留最後失敗的 job, default: 1

## Time zones
CronJobs default 是使用 local time zone  
可以使用 .spec.timeZone` 進行指定  
detail: [Time zones](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones)

---

cronjob 概念非常簡單  
基本就是在 job 基礎上加上排程的功能而已  
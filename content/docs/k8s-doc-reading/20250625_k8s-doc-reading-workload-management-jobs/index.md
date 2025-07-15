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

job 提供一次行的工作  
同時也確保 pod 必須成功結束(successfully complete)  
否則 k8s 就會一直重複執行  

直接來看 sample 

```bash
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

backoffLimit 指的是當 pod 失敗次數到達時  
因為該 job fail  
k8s 會進入 back-off delay (以 10s, 20s, 40s ...遞增,上限 6 分鐘)  
也就是說當 pod 失敗 4 次, 就 deplay 10s 再次執行該 pod

該 sample 會執行一個 job 進行 pi 的計算  
pod 執行結束後會進入 Completed 狀態  
與 deployment 不同, deployment 會一直 pod 執行 哪怕是 success complete   


## Parallel execution for Jobs 

job 能夠設定為並行處理  
預設情況下 job 只會執行一個 pod 並執行一次 
可以設定以下兩個參數來達成 Parallel  

`.spec.completions`: 該 job 需要執行幾次
`.spec.parallelism`: 該 job 允許幾個 pod 平行處理  
修改後的 manifest 如下  
```bash
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
  completions: 10
  parallelism: 3
```

此即告訴 k8s 平行執行三個 pod, 最終要執行 10 個 pod   

## Pod failure policy 
因為預設情況 pod 如果失敗 job 只會一直重新執行 pod  
pod fail policy 控制出現特定情況時 就直接當作 job 失敗 不再執行 pod  

detail 可見 [pod-failure-policy](https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-failure-policy) 

## Success policy
在部份情況 job 的平行處理可能僅為嘗試找出正確結果  
因此可以設定成功條件來提早完成 job  

detail 可見 [Success policy](https://kubernetes.io/docs/concepts/workloads/controllers/job/#success-policy) 

## cleanup 
job default 必須手動刪除  
可以加上 `.spec.ttlSecondsAfterFinished` 來自動刪除  

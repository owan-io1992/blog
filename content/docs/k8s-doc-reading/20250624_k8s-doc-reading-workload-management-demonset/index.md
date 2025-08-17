---
date: 2025-06-24T06:24:00
draft: false
tags:
- k8s-reading
title: "Concepts - Workload Management - daemonset"
weight: 10
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)   


daemonset 用途在每個指定的 node 上都啟動同樣 pod  


參考用途: 
- running a cluster storage daemon on every node  
- running a logs collection daemon on every node  
- running a node monitoring daemon on every node  

簡單來說
daemonset 用來啟動 node 所需要的基本工具 monitor or collector (as pod)  
因此 node 安裝 k8s 後, 剩下所需要的 daemon 就可以交給 k8s 執行  
不須再透過 systemd 來執行  
## sample daemonset

```bash
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      tolerations:
      # these tolerations are to have the daemonset runnable on control plane nodes
      # remove them if your control plane nodes should not run pods
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      containers:
      - name: fluentd-elasticsearch
        image: quay.io/fluentd_elasticsearch/fluentd:v2.5.2
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
      # it may be desirable to set a high priority class to ensure that a DaemonSet Pod
      # preempts running Pods
      # priorityClassName: important
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
```

要注意 DaemonSet 沒有 replica 功能   
他就是在每個 node 上面執行一樣的 pod  
不會有 node 的差異  

這邊新出現一個 **tolerations**  
他是與 Taints 設定相關  
快訴解釋  
Taints(污點) 設定在 node 上, 告訴 scheduler 該 node 有瑕疵的概念  
scheduler 就會避免將 pod schedule 到這些有 Taints 的 node 上  
  
tolerations(容忍) 就讓 scheduler 忽略 node 身上的 Taints  

藉此來讓 node 避免被使用  
預設情況下 control-plane node 會加上 Taints  
因此 user workload 並不會被 schedule 到 control-plane node 上  

因此  此處的 tolerations 設定就是忽略 control-plane node 身上的 Taints  
> 在 k8s 1.19 以前叫 master  
> k8s 1.20 改叫 control-plan  
> 是同樣性質的設定, 這邊是為了新舊相容因此兩個都設定  



此範例是啟動一個 log collector  
將 node 的 `/var/log` mount 給 pod  
因此 pod 可以讀到 node 的 `/var/log` file  
就能將 log forward 給 log server   

---

其餘部份都與 deployment 相差無異  

而前面有提到可以全部或部份 node 執行 daemonset  
可以用 nodeSelector or nodeAffinity 來達成  


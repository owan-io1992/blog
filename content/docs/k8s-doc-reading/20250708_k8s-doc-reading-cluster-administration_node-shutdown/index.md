---
date: 2025-07-08T06:06:00
draft: false
tags:
- k8s-reading
title: "k8s doc reading: Concepts - cluster-administration - node-shutdown"
weight: 28
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/cluster-administration/node-shutdown/)   
[doc link](https://kubernetes.io/blog/2021/04/21/graceful-node-shutdown-beta/)
[doc link](https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/)
[doc link](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)

在 k8s 中可能會需要維護需求而重開 node, 舉例更新 k8s, system, firmware  
因此 k8s 提供 graceful shutdown 機制讓我們能夠停機  

另外這篇也順帶了解如果 node 發生非預期的狀態 k8s 會如何處理  

而 shutdown node 有兩種方式  
人為 trigger, 或是由 infra trigger  
所謂的 infra trigger  
可能是因為停電而收到 shutdown signal  
或是在 cloud 環境會因為 spot 環境收到 shutdown signal  
因為 infra trigger 是自動發生的  
所以 k8s 也提供 graceful shutdown 的機制  

## manual graceful node shutdown 
先說人為的部份, 舉例來說定期更新系統需求, 會要 graceful node shutdown  

這部份除了用前面說的 [taint-and-toleration](/posts/20250704_k8s-doc-reading-taint-and-toleration/)  
k8s 提供一個 Safely Drain a Node 的方法  

關於這部份 其實在前面已經提過 因此就直接超連結過去 [maintain-a-node](/posts/20250617_k8s-doc-reading-concepts-cluster-architecture-node/#maintain-a-node/)  

## auto graceful node shutdown 
再來說說自動的部份  
由於執行中的 pod 是由 kubelet 管理  
因此 graceful shutdown 會設定 kubelet 在  
當 kubelet 收到 stop signal 時 會進行 [normal pod termination process](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination)  

其中 pod 有細分 `normal pod`, `critical pods`
> 關於 `critical pods` 可以參考 [doc](https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/#marking-pod-as-critical)  


設定部份, 有
- shutdownGracePeriod  
  設定 `normal pod`, `critical pods` 總共的 graceful terminal 時間, default 0
- shutdownGracePeriodCriticalPods
  設定 `critical pods` 的 graceful terminal 時間, default 0

假設 shutdownGracePeriod=30s, shutdownGracePeriodCriticalPods=10s  
那 0-20s 會是 shutdown normal pod  
21-30s 會是 shutdown critical pod  

而由於 default 都是 0, 因此實際上 k8s default 並沒有啟動 graceful shutdown  


**setup**   
首先要寫 [config file](https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/)  

vi /etc/kubernetes/kubelet.conf
```bash
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
shutdownGracePeriod: 30s
shutdownGracePeriodCriticalPods: 10s
```

> 詳細 config 參數可參考 https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/  

接著執行 `sudo systemctl edit kubelet` 在 kubelet 加上啟動參數 `--config=/etc/kubernetes/kubelet.conf`  


如果跟我一樣是 k3s 環境  
則是把 [config](https://docs.k3s.io/installation/configuration) 放到 `/var/lib/rancher/k3s/agent/etc/kubelet.conf.d/nodeGracefulShutdown.conf`  


## Non-graceful node shutdown handling 

由於 k8s 會自動監測 pod status, 基本上如果採用 deployment 佈署  
當 pod 數量不滿足時會自動補齊  

但 statefulset 就不一樣了  
由於其 stateful 特性, pod 會因為沒有正常 terminate  
導致 pod 永久卡在 terminating 狀態

另外就是 pod 如果有掛 volume `VolumeAttachments` 也會卡住無法 detach   


這時會需要人工介入  
要用到我們之前的 taint  
加上 `node.kubernetes.io/out-of-service`, 不管 NoExecute or NoSchedule    
這時 k8s 會 force delete pod, 並且 detach volume  

---

以上熟悉 node shutdown behavior 之後  
要管理 node 會就更得心應手  
一切交給自動化協助, 更能將時間用在有用的地方   


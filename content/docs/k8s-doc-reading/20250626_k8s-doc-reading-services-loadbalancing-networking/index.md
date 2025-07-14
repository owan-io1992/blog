---
date: 2025-06-26T04:41:00
draft: false
tags:
- k8s-reading
title: "k8s doc reading: Concepts - Services, Load Balancing, and Networking"
weight: 14
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/services-networking/)   


在 k8s 中網路由幾個部份組成

- 每個 pod 有屬於自己的 cluster IP(pod network,also call cluster network)  
  如果 pod 有多個 container, 他們可以使用 localhost 溝通  
  但也因此 container 之間 port 不能 conflict  
  但要記得 這基本上是透過 Container Networking Interface (CNI) 建立起 pod network  
- pod 可以直接與其他 pod 溝通, 就算在不同 node  
- service API 提供 service IP 來當作 cluster 內部的 loadbalancer  
  可以 host 一個或多個 pod  
  如果 replica 發生變化, service 也會跟著改變  
  也因此 service 讓 replica 的應用變得相當簡單  
  該功能由 service proxy (kube-proxy 提供)  
- ingress/gateway 讓外部能夠存取 cluster 內部的 pod  
  - Service API's type: NodePort or LoadBalancer 也行  
    另外還有 host port / host network  
- NetworkPolicy 可以保護 pod 之間/甚至外部的流量存取,(此功能基本上由 CNI 實做)


這邊要特別說明 k8s implement 的項目
- pod network  ❌  
- service  
  - ClusterIP  ✅  
  - NodePort  ✅  
  - LoadBalancer  ❌  
  - ExternalName  ❌  
- ingress  ❌  
- gateway  ❌  
- NetworkPolicy  ❌  


---  
以上是快速的概述  
關於 pod network 可以參考 [Networking and Network Policy](https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy)  

如果是 k3s 的環境  
預設情況下已經安裝好 Flannel(CNI) & kube-router(NetworkPolicy)   
如果是其他 distro 就可能須先自行安裝才能使用  

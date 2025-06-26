---
date: 2025-06-16T09:33:00
draft: false
tags:
- k8s-reading
title: "k8s doc reading: Concepts: Cluster Architecture"
---
![alt](images/banner.png)  

<!--more-->

[doc link](https://kubernetes.io/docs/concepts/overview/components/)  

先對 k8s 架構有一定程度的了解後  
會更容易上手 k8s  
首先 k8s 本身就是設計成 cluster 模式  
會先把 node 分成兩大 node group

- Control plane: 負責執行 k8s cluster 管理元件  
  一般來說一個 production ready cluster 會準備 3 個 Control plane node (HA)  
  他只會執行 k8s 核心元件  
  預設不會執行 k8s 本身以外的 container  
- worker: 執行我們 user workloads (container)

![](images/architecture1.png)


## component 介紹
以下我認為大概知道即可  
除了在 debug cluster issue 外  
一般在操作其實不太會碰到  

### kube-apiserver
API server 是負責 component /operator 之間溝通的橋樑  
不管是機器還是人都是要照著 Kubernetes API 的規範溝通  
如果連不上 API server 意味著失去對 cluster 的控制能力


### etcd 
簡單來說就是 k8s 的資料庫  
預設就是以 HA 的方式運作  

### kube-scheduler
我們實際在使用 k8s 時, 會告訴他我們的期望執行 container 的條件  
比如說 cpu/memory 需要多少, 該執行在什麼 cpu architecture 上, 甚至是 node type (有無 GPU 之類的)   

scheduler 負責根據我們的設定 編排 container 在符合條件的 work node 上執行   


### kube-controller-manager
Control plane component that runs controller processes.

Logically, each controller is a separate process, but to reduce complexity, they are all compiled into a single binary and run in a single process.

There are many different types of controllers. Some examples of them are:

Node controller: Responsible for noticing and responding when nodes go down.
Job controller: Watches for Job objects that represent one-off tasks, then creates Pods to run those tasks to completion.
EndpointSlice controller: Populates EndpointSlice objects (to provide a link between Services and Pods).
ServiceAccount controller: Create default ServiceAccounts for new namespaces.
The above is not an exhaustive list.

簡單來說  
就是除了上述以外的雜務都是這個 compoment 負責      

### cloud-controller-manager 
這是 option component  
除非你有用 cloud provider (公有雲/私有雲)  
才有這 component,  但基本上 cloud provider 舉例 EKS  
不會讓你接觸到 control-plane  
所以也不用太過了解 care  

### kubelet
簡單來說，kubelet 是每個 work node 上的主要代理程式。它負責確保 Pod 中的容器正常運行。  
它會監控 API server 傳來的 Pod 定義，並確保這些 Pod 及其容器在節點上被正確地啟動、運行和維護。  

### kube-proxy
kube-proxy 負責處理 Service 的網路代理，它會根據 Service 的定義，在每個節點上維護網路規則（例如 iptables 或 IPVS 規則），以實現 Service 的負載平衡和網路轉發，確保流量能夠正確地導向到後端的 Pod。   


### Container runtime 
就是負責執行的 container 的 component   
基本上建議使用 containerd  

## Addons
提供 cluster features 
基本上這些 pod 會長在 namespace `kube-system`  
> **namespace**
> 用來隔離 k8s 內不同 objects 的基本 group  
> 預設會有
> **default**
> **kube-system**
> 可以理解為區分不同 user 用的 group  


### Cluster DNS
k8s 透過 DNS 來讓 container 找到彼此   
因此會有個 DNS server 在 cluster 內(coreDNS)  

### Web UI (Dashboard)
讓大家方便管理 k8s 的 Dashboard  
預設不會安裝  
不過個人覺得看看就好  
因為很陽春  一般會採用其他 solution  

### Container resource monitoring
k8s 沒有 implement 先略過  

### Cluster-level Logging 
k8s 沒有 implement 先略過  

### Network plugins
k8s 沒有 implement  
但缺他不可
簡單來說每個 container 都會有存取網路的需求   
而這必須夠過 CNI(container network interface)達成, 也就是 Network plugins   

k8s 跟 docker 不同的是 
docker 不需要額外設定, contianer 就有網路功能  

k8s 必須再額外安裝 CNI 才能運作  
而 CNI 會有琳瑯滿目的選擇  
這邊可以看到官方已列出的 plugin [networking-and-network-policy](https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy)

不同的 CNI 不只 implement 方式不同  
feature 也會不同  
比如說有沒有 VPN or firewall 的功能  

不同的 CNI 各自有各自的好壞  
後面會再介紹  

## Architecture variations 
簡單來說 k8s 的安裝其實可以根據需求產生變化  
舉例來說 control-plane 也能執行 user workloads  

### Traditional deployment
Control plane components run directly on dedicated machines or VMs, often managed as systemd services.

畢竟也是要有人管理 k8s 的運作  
通常透過 systemd  

### Static Pods
Control plane components are deployed as static Pods, managed by the kubelet on specific nodes. This is a common approach used by tools like kubeadm.  

這裡第一次出現 pod 這個詞  
說明一下 pod 是 k8s 最小部屬單位  
是一個 container 的 group    
k8s 能讓多個 container 能夠共用 network/volume resource  > 形成一個 pod  
後面會再詳細說明  

而 Static Pods 則是相當特別的 pod  
其他的 pod 都是透過 scheduler 編排後透過決定是否交給 kubelet 啟動  

Static Pods 則是跳過 scheduler, kubelet 直接啟動  
通常都是執行系統 component  
我們一般不會使用 Static Pods  

### Self-hosted
The control plane runs as Pods within the Kubernetes cluster itself, managed by Deployments and StatefulSets or other Kubernetes primitives.

把 control plane 執行在 k8s 自身  
算進階玩法  
有興趣可以嘗試

### Managed Kubernetes services
Cloud providers often abstract away the control plane, managing its components as part of their service offering.

簡單來說就是 Cloud providers 基本上不會讓你有管理 control plane 的能力 (都是他們代管)  

## Workload placement considerations 

The placement of workloads, including the control plane components, can vary based on cluster size, performance requirements, and operational policies:  

k8s 架構是可以根據需求調整的  

* In smaller or development clusters, control plane components and user workloads might run on the same nodes.  
在小型開發環境可以只有一個 control plane node (沒有 HA)  
並 allow 執行 user workloads  
用 single node 執行開 k8s  


* Larger production clusters often dedicate specific nodes to control plane components, separating them from user workloads.  
在正式環境  
請分開 control plane, workload (通常可能 3 control plane node + 3 work node)  
不過 k3s 預設不這樣設計  都是看需求   

* Some organizations run critical add-ons or monitoring tools on control plane nodes.  
雖然不讓 control plane 執行 user workloads    
但是允許讓 monitor 類的 workloads 在 control plane node 執行    
當然是用來 monitor control plane 了   
這邊會讓各位先知道  可以根據設定  
讓部份 workload 不能在 control plane node 執行  
讓部份 workload 可以在 control plane node 執行  

## Cluster management tools 

社群中有很多 cluster 管理工具  
這後面再找個篇幅介紹  

## Customization and extensibility 
Kubernetes architecture allows for significant customization:  

* Custom schedulers can be deployed to work alongside the default Kubernetes scheduler or to replace it entirely.
* API servers can be extended with CustomResourceDefinitions and API Aggregation.
* Cloud providers can integrate deeply with Kubernetes using the cloud-controller-manager.
The flexibility of Kubernetes architecture allows organizations to tailor their clusters to specific needs, balancing factors such as operational complexity, performance, and management overhead.

基本上就是再次強調  
k8s 的彈性  
因此造就他的強大  


---  

以上是 k8s 的基本介紹  

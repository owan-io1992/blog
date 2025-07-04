---
date: 2025-07-04T03:09:00
draft: false
tags:
- k8s-reading
title: "k8s doc reading: Concepts - configuration - Assigning Pods to Nodes"
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)   

k8s 是 cluster 架構,意味他能夠管理很多 node  
但是 node 之間可能存在些許差異  
比如說不同的 CPU/memory/disk/availability zone  

因此 k8s 能設定一些 constraints 來調整 pod 要使用哪些 node   
所有的一切都是依靠 node 上面設定的 label 來做決定  
通常來說會用 group 方式來設定 label(多個 node 有相同 label)  
比如說 A,B,C 主機是 az=1  
比如說 D,E,F 主機是 az=2  


- nodeSelector  
  直接指定符合 label 的 node, 最簡單的使用方式  
- Affinity and anti-affinity  
  與 nodeSelector 比起來更有彈性, 除了硬性(hard) 規則必須滿足 label 條件外  
  也可以使用軟性(soft) 規則, 即便不滿足也允許使用 node, 來提昇彈性  
- nodeName  
  直接指定 node  
- Pod topology spread constraints  
  預設情況下 replica 會平均 place 在多個 node 上  
  這邊可以規定要分 AZ or 怎麼"平均" place 在多個 node 上  
  算進階需求  
  
個人的建議是使用 Affinity  
因為使用上較彈性  


## nodeSelector

```bash
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
  nodeSelector:
    atchitecture: arm64
```

使用很簡單  
就是設定 key-value 指定 label  
只有都符合的 node 才會被 place pod  

## Affinity and anti-affinity  
affinity 能夠設定更多條件  使用上會更有彈性  
Affinity 又細分  
Node affinity  
Inter-pod affinity/anti-affinity  

## Node affinity 
就是指定 node  
其中又分 required(hard) 與 preferred(soft)  

而設定參數超級長... `requiredDuringSchedulingIgnoredDuringExecution` and `preferredDuringSchedulingIgnoredDuringExecution`  

基本上看開頭 required 與 preferred 即可了解差異  
而這兩者又可以組合使用  
直接看範例  

```bash
apiVersion: v1
kind: Pod
metadata:
  name: with-affinity-preferred-weight
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/os
            operator: In
            values:
            - linux
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: label-1
            operator: In
            values:
            - key-1
      - weight: 50
        preference:
          matchExpressions:
          - key: label-2
            operator: In
            values:
            - key-2
  containers:
  - name: with-node-affinity
    image: registry.k8s.io/pause:3.8
 ```

範例因為設定 `requiredDuringSchedulingIgnoredDuringExecution`  
因此只有 label `kubernetes.io/os=linux` 的 node 才會被 place  
然後 preferredDuringSchedulingIgnoredDuringExecution 又設定兩個不同的權重(weight)  
由於 `label-2=key-2` 權重較高, 因此會偏好使用符合此 label 的 node  

另外 operator 用法可以參考 [doc](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#operators) 


### Inter-pod affinity and anti-affinity 
node affinity 是根據 node label 決定 place  
pod affinity 則是根據 pod label  
舉例來說 會希望 app 跟 DB 這兩個 pod 住在同個 AZ 下甚至同個 node, 來降低 network overhead  
或是希望避開不同 DB 在同個 node, 提昇高可用性  
> 由於該設定是比對 pod label, 會造成 scheduler 很大 loading  
> 官方建議 cluster node 大於 1000 時不要使用  

一樣用範例解釋  

```bash
apiVersion: v1
kind: Pod
metadata:
  name: with-pod-affinity
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: security
            operator: In
            values:
            - S1
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: security
              operator: In
              values:
              - S2
  containers:
  - name: with-pod-affinity
    image: registry.k8s.io/pause:3.8
```

由於 podAffinity required 的關係  
pod 必須跟 label 含有 security=S1 的 pod 住在同個 node 上  

由於 podAntiAffinity preferred 的關係  
pod 會偏好避免跟 label 含有 security=S2 的 pod 住在同個 node 上  

## nodeName

```bash
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
  nodeName: kube-01
```

使用很簡單  
就是設定 node name


---

以上能夠讓我們決定 pod 該住在哪個 node 上  
是很常用的需求  
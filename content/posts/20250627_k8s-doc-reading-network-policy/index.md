---
date: 2025-06-28T10:40:00
draft: false
tags:
- k8s-reading
title: "k8s doc reading: Concepts - Services, Load Balancing, and Networking - networking policy"
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/services-networking/network-policies/)  

k8s default 情況下 pod 跟 pod 之間可以任意存取  
如果是在忽安全性的組織就必須加以管控  

networkploicy 可以做到  
- pod 隔離  
- namespace 隔離  
- IP 隔離  

其中 pod 跟 namespace 是使用 selector 方式隔離  


另外要注意 network policy 是由 CNI implement  
因此要注意採用的 CNI 是否支援  
而 k3 較特別, 是利用 kube-router's netpol controller 達成 

## sample config 
設定可以分為 ingress & egress (進跟出)  
並且 default 情況下是沒有任何 policy (both allow in/out)  

```bash
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
    - namespaceSelector:
        matchLabels:
          project: myproject
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 6379
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24
    ports:
    - protocol: TCP
      port: 5978
```

以下說明  
 
**podSelector**: 選擇要 apply 這個 policy 的 pod
**policyTypes**: 如為設定 Ingress 一定會啟動, 如果有 Egress rule 則會啟用 Egress  
**ingress**: 設定允許的規則, 也就是說 default 會全擋 any input request  
**egress**: 設定允許的規則, 也就是說 default 會全擋 any output request  

## behavior of `to` and `from`

要特注意 `to` or `from` 下面的 list 之間是 or 的關係  

```bash
  ...
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          user: alice
    - podSelector:
        matchLabels:
          role: client
    ports:
    - protocol: TCP
      port: 6379
  ...
```
`namespaceSelector`, `podSelector` 都是在同一層 from 的 list  
因此此處的規則是 來源 namespace 包含 label `user: alice`  
或者
來源 pod 包含 label `role: client` 都可以通過
另外兩者都只能通過 6379 port  


如果是要 and 的關係 則可以把多個 Selector 放在 同個 list 內  

```bash
  ...
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          user: alice
      podSelector:  # 此處有差別
        matchLabels:
          role: client
    ports:
    - protocol: TCP
      port: 6379
  ...
```

那麼 `namespaceSelector`, `podSelector` 兩者就是 and 的關係了  

## notices
1. 要特別注意的是當 pod 建立時  
network ploicy 因為是透過 CNI implement  
可能會時間來生效

2. 使用 `hostNetwork` 的 pod 可能無法生效  
   必須根據不同的 CNI 實做 network policy 來判斷  

3. 對已存在的 connection 可能不會生效  
   必須根據不同的 CNI 實做 network policy 來判斷  


---

對於 k8s 的 network policy 他只能做基本的 tcp/ip 防護  
如果要更進階例如 7 層的防護  
必須使用其他 solution  
---
date: 2025-07-04T13:32:00
draft: false
tags:
- k8s-reading
title: "k8s doc reading: Concepts - scheduling-eviction - Taints and Tolerations"
weight: 27
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)   
 
前面說的 node selector, affinity  都是讓 pod 去選擇 node  
Taints and Tolerations 則是反過來 能夠拒絕 pod place 到 node 上   

這可以用在一些相對特殊用途的 node  
比如說 conprol-plan node 在 k8s 中預設不會執行 user workload , 就是使用 taint 達成  

- Taints(污點)
  設定在 node 上, 讓 scheduler 避開該 node 

- Tolerations(容忍)  
  設定在 pod 上, 允許 scheduler 容忍 node Taints  


## taint
taint 設定在 node 上  
有以下兩個設定  
- **NoSchedule**
  新的 pod 會不能 place 在 node 上, 不影響既有執行中的 pod  
- **NoExecute**
  除了新的 pod 會不能 place 在 node 上  
  既有的 pod 也會被 evict  

**example config **
```bash
# add 
kubectl taint nodes node1 key1=value1:NoSchedule

# remove
kubectl taint nodes node1 key1=value1:NoSchedule-
```

如此一來, scheduler 會避開該 node1 palce pod  


## tolerations 
tolerations 設定在 pod 上  

參考設定
```bash
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"
```

如此一來 此 pod 就可容忍 taint  
也就是說 除了這個 pod 之外, 其他 pod 一樣無法使用 node1  

### effect
effect 有以下幾個設定  
- **NoSchedule**  
  容忍 taint `NoSchedule`  
- **PreferNoSchedule**
  soft 版本容忍 taint `NoSchedule`  
  但從字面的意思會讓人認為優先使用 taint node  
  實際上是避免使用 taint node  
- **NoExecute**
  容忍 taint `NoExecute`  
  另外如果有設定 `tolerationSeconds`, 會讓 pod 只能 toleration 這段時間, 換句話說 超過 `tolerationSeconds` pod 依舊會被 evict  
  但是要特別注意新的 pod 因為會有 `tolerationSeconds` 所以他又可以被 place 到 taint node 上  
  直到超過 `tolerationSeconds` 再次被 evict  
  因此如果有使用 `NoExecute`,  建議同時設定 `NoSchedule`  


### operator  
operator 有以下幾個設定

- **Exists** 且不設定 value, match 該 key 所有 value  
- **Equal**  match 該 key and value  

另外 key 如果忽略, operator 必須是 `Exists`  
代表 match 該 effect 所有 key/value   

如果 effect 未設定則 match 所有 effects  


最後也可以 match 所有 effect's key/value, 就是只設定 `operator: "Exists"`
```bash
tolerations: 
  - operator: "Exists"
```


---


以上就是 Taints and Tolerations  
在 k8s 中要讓某些 node 有特殊用途就靠他  
藉此避免閒雜人等使用該 node   
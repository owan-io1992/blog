---
date: 2025-06-27T03:47:00
draft: false
tags:
- k8s-reading
title: "k8s doc reading: Concepts - Services, Load Balancing, and Networking - ingress"
weight: 16
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/services-networking/ingress/)   

ingress 簡單來說就是 reverse proxy  
他只能處理 http/https 的 protocol  
為了提昇相容性, k8s 另外新增了 gateway API(下一篇會提到) 來支援 tcp/udp  

因為 gateway API 就是下一代的 ingress 基本能完全取代 ingress  
不過從官方介紹來看  
ingress 沒有 deprecate 的打算  
https://gateway-api.sigs.k8s.io/faq/#will-gateway-api-replace-the-ingress-api  


因為 k8s 沒有 implement ingress, 能不能轉換到 gateway API 必須看 implement 的 project 有沒有辦法支援   
而 gateway API 也是, k8s 並沒有 implement  
因此種種原因並不會 deprecate ingress  

那到底還要不要學 ingress 呢？  
目前來說學 ingress 不虧, 有由淺入深的感覺  
另外因為 k8s 沒有 implement ingress  

## why ingress ?  
ingress 帶來一些好處  
比如說 SSL terminal  
route by api...等好處  

是我目前個人最推薦讓 k8s 對外提供存取的方式  

## What is Ingress?
官方的架構圖  我認為不是很好理解  
於是我重劃一個 flow chart  
```mermaid
graph LR;
  client([client])
  lb[Ingress-managed <br> load balancer]

  subgraph cluster
  service_nodeport[service <br> NodePort]
  service_lb[service <br> loadbalancer]
  pod_ic[pod <br> ingress controller]
  ingress;
  service;
    subgraph pods
    pod1[Pod1]
    pod2[Pod2]
    end
  end

  client ==> lb
  lb ==> service_lb ==> pod_ic
  client -.-> service_nodeport -.-> pod_ic
  client -. host network or host port .-> pod_ic
  pod_ic == read config === ingress
  pod_ic -.-> service -.-> pods
  pod_ic ==> pods
  classDef plain fill:#ddd,stroke:#fff,stroke-width:4px,color:#000;
  classDef k8s fill:#326ce5,stroke:#fff,stroke-width:4px,color:#fff;
  classDef cluster fill:#fff,stroke:#bbb,stroke-width:2px,color:#326ce5;
  class ingress,service,pod1,pod2,service_nodeport,service_lb,pod_ic k8s;
  class client,lb plain;
  class cluster cluster;
```

首先 實線的部份 是建議做法  
虛線則是也可以這樣玩  

**首先先看實線部份**  
前面說 k8s 並沒有 implement ingress  
於是能用之前要先安裝 ingress controller, 也就是實際 implement ingress 功能的 'pod'  
是的 ingress controller 會以 pod 形式存在於 k8s 中  
他會向 k8s 宣告一個 ingress class  
我們在新增 ingress 時會指向一個 ingress class  
這樣 k8s 就知道該 ingress 實際由哪個 ingress controller 處理  
換句話說 k8s 中能安裝多個 ingress controller  

而 ingress 由哪個 ingress controller 處理, 這句話的意思是  
ingress 本身就只是一個 config, 他不具有任何 computing 能力(無法實際處理 request)  
ingress controller 會 read ingress 後知道該怎麼處理 request  
所以實際在處理 request 是 "ingress controller"  

所以! 所以! 所以!  
client 發起的 request 要能夠進到 cluster 內  
是要將 request 送給 ingress controller  
於是外面的 request 量很大的話! 記得也要關心 ingress controller loading  
不夠的話請記得 scale-out ingress controller  

再來 ingress controller 如何 forward request to pod  
基本上 ingress controller 為了能夠做更細部的控制  
比如說 loadbalance mode (leastconn,roundrobin,random...)  
大部分的 ingress controller 不會再透過 service forward request  
而是直接知道有哪些 pod 可以送 request, 並直接送給 pod  


**虛線部份**  

在說明完實線後  
虛線的部份就可以輕易理解了  
基本上只要目的能夠達成  
怎麼做都可以

client 部份可以透過 NodePort or host network or host port 達成
host network and host port 可以直接理解為 docker 的 host network 跟 port forward  
兩者都是直接在 pod 開啟對外 access  
這些做法在 on-primes 很好用 可以直接省下一個 loadbalance  

另外根據情況 ingress controller 可以將 request 送給 service  
不過當然會喪失 loadbalance mode 能力... etc  
 
## install ingress controller 

k8s 官網有列出可用的 [ingress-controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)  
當然是包含但不限於了  

如果是初學者 可以安裝 k8s 維護的 [ingress-nginx](https://github.com/kubernetes/ingress-nginx/blob/main/README.md#readme)  

要注意的是 ingress-controllers 清單上面你會看到兩個 nginx  
ingress-nginx 是 k8s 維護  
nginx-ingress-controller 則是由 F5 官方維護  
功能/使用上會有差異  

而不只 nginx 會鬧雙胞胎, haproxy 也是  
因此在使用上需要特別注意  

而每一家 ingress controller 安裝方式會不同, 必須去看他們的 doc 才行  

但如果我們使用 k3s 的話  
default 已經幫忙安裝 treafik ingress controller  
可以直接開始使用  

## sample config 

```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-foo-bar
spec:
  rules:
  - host: "foo.bar.com"
    http:
      paths:
      - pathType: Prefix
        path: "/bar"
        backend:
          service:
            name: service1
            port:
              number: 80
```

快速說明下
.spec.rules[0].host: 指定收到該 host 的 request 才套用此 ingress 
.spec.rules[0].path: 可以指定 uri forward 給對應的 service 的 pod   
通常來說 ingress controller 會將 request 直接送給 pod  

## getting start with helm 
接來我們安裝一個 httpbin server 並使用 ingress 來 expose  

```bash
helm repo add owan-charts https://owan-io1992.github.io/helm-charts/
helm repo update

helm upgrade --install my-httpbin owan-charts/httpbin --version 0.1.6 \
  --set ingress.enabled=true \
  --set ingress.className=traefik
```

test
```bash
node_ip=<your k8s node ip>
curl http://chart-example.local --resolve chart-example.local:80:${node_ip}
```

來看看 ingress object  
```bash
$ k get ingress
NAME         CLASS     HOSTS                 ADDRESS          PORTS   AGE
my-httpbin   traefik   chart-example.local   192.168.56.101   80      4m49s
```

可以看到有個 object 'my-httpbin' 使用 ingress class 'traefik' 並 forward host 為 chart-example.local 的 request  
至於 ADDRESS 跟 PORTS 的部份參考即可, k8s 不會列出全部    
這邊因為 k3s 會 listen 所有 node 的 80,443 port 給 traefik  
所以 request 送給任一 node 的 80,443 都行  

想看看 yaml 怎麼寫的  
可以用 `k get ingress my-httpbin -o yaml`  

---

以上就是 ingress 的快速設定  
事實上 ingress 能做的事情很多  
比如說 loadbalance mode  
ssl terminal  
因此是很常見的 expose service 的方法  
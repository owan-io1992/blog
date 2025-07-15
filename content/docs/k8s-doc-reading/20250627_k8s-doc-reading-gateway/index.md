---
date: 2025-06-28T05:24:00
draft: false
tags:
- k8s-reading
title: "Concepts - Services, Load Balancing, and Networking - gateway API"
weight: 17
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/services-networking/gateway/)   

ingress 很強大  
但他的敗筆是他只能處理 http/https 的 protocol  
如果要支援 tcp/udp 以前的作法是使用 CRD 去擴充 k8s  
比如說 [nginx TransportServer](https://docs.nginx.com/nginx-ingress-controller/configuration/transportserver-resource/)  

Gateway API 本身也是一個 CRD  
但因為他對 API 有統一的規範  
因此在不同 implement 切換 & 使用上較容易  

所以如果你有需求使用 [nginx TransportServer](https://docs.nginx.com/nginx-ingress-controller/configuration/transportserver-resource/)  , 那會建議直接使用 [nginx-gateway-fabric](https://docs.nginx.com/nginx-gateway-fabric/)  
這種使用 gateway API 規範的 soluction   

## install gateway controller 

可以參考 [gateway implement status](https://gateway-api.sigs.k8s.io/implementations/#gateway-controller-implementation-status)

不過由於 k3s 並沒有讓 traefik 支援 gateway API (traefik default 沒有 enable)  
因此我們要來手動 enable  

k3s default 是使用 Helm Controller 去安裝 traefik  
可以使用 HelmChartConfig 去修改 chart default 值
新增 file `traefik_gateway-API.yaml`  
```bash
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    providers:
      kubernetesGateway:
        enabled: true
```

apply  
```bash
k apply -f traefik_gateway-API.yaml 
```

check  
```bash
$ k get gatewayclasses
NAME      CONTROLLER                      ACCEPTED   AGE
traefik   traefik.io/gateway-controller   True       20s
```

以上完成讓 k3s 內建的 traefik 支援 gateway API  


## getting start with helm 


```bash
helm upgrade --install my-httpbin owan-charts/httpbin --version 0.1.6 \
  --set gateway.enabled=true \
  --set gateway.gatewayClassName=traefik
```

test
```bash
node_ip=<your k8s node ip>
curl http://chart-example.local --resolve chart-example.local:80:${node_ip}
```


gateway API 在設定上會分為多個 object  
這邊為例  
```bash
$ k get gateway
NAME         CLASS     ADDRESS          PROGRAMMED   AGE
my-httpbin   traefik   192.168.56.101   True         18m

$ k get httproutes
NAME         HOSTNAMES                 AGE
my-httpbin   ["chart-example.local"]   20m


$ k get gateway my-httpbin -o yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-httpbin
  namespace: default
spec:
  gatewayClassName: traefik
  listeners:
  - allowedRoutes:
      namespaces:
        from: Same
    name: http
    port: 8000
    protocol: HTTP

$ k get httproutes my-httpbin -o yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-httpbin
  namespace: default
spec:
  hostnames:
  - chart-example.local
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: my-httpbin
    namespace: default
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: my-httpbin
      port: 8080
      weight: 1
    matches:
    - path:
        type: PathPrefix
        value: /
```

gateway: 定義從哪裡收 request  
httproutes: 如何做 routing, 並將此 routing 附加在 gateway 上(parentRefs)  

由於分成多個 object  
且 gateway 不負責設定使用哪些 routes  
而是讓 httproutes attech 進來 會稍微有點反邏輯的感覺  

實際上 gateway 會像是 ingress class  
httproutes 像是 ingress  
這部份要再花時間習慣  


---

關於 gateway 的使用細節  可以參考 doc  
https://gateway-api.sigs.k8s.io/guides/simple-gateway/

由於他支援的 protocol 更多  
使用上更加複雜  
因此 ingress 仍然有他的優勢在  

---
date: 2025-07-04T01:09:00
draft: false
tags:
- k8s-reading
title: "k8s doc reading: Concepts - configuration - Liveness, Readiness, and Startup Probes"
weight: 24
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/)   
[doc link](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)   


probes 用來監控 pod 的狀態  
如果發生異常時, k8s 就會主動介入  
藉此可以一定程度保持 workload healthy  


其中分為 Liveness, Readiness, Startup  

|                    | Liveness     | Readiness                  | Startup                   |
|--------------------|--------------|----------------------------|---------------------------|
| continuous monitor | yes          | yes                        | no                        |
| fail behavior      | restart pod  | mark pod notReady          | mark pod notReady         |

## probes
### Liveness probe
Liveness 用來確保 pod 正常運作
當 Liveness probe monitor 到 fail 時  
就會把 pod 進行重起  

要注意 Liveness 與 Readiness 是獨立運作  
因此兩者可以設定不同條件來產生不同效果  

如果 pod startup 時間會較長, liveness 會認為 pod 異常而 restart pod > 變成 always restart pod  
這時可以加上 `initialDelaySeconds` 參數或配合 Startup probe 使用  

在 pod 生命週期, Liveness probe 會持續監控  

### Readiness probe
Readiness 用來確保 pod 可以開始接收 request (READY)  
當 check success 時, 就會將 pod 加入 service 的 endpoints(開始接收 request)  
而當 monitor 到 fail 時, 會將 pod 移除 service 的 endpoints, 不會重起 pod  
藉此如果 pod loading 過高時, 可以讓他把 loading 消化完 再繼續接收 new request  

與 Liveness probe 合併使用時  
可以設定 Readiness 先 fail  (failureThreshold: 3)  
如果超過一定時間尚未恢復則讓 Liveness probe 進行 pod restart  (failureThreshold: 6)  

在 pod 生命週期, Readiness probe 會持續監控  

### Startup probe
用來確保 pod 已經 startup 完成  
如果設定了 Startup probe, 在其 success 之前  
會先暫停 Liveness probe & Readiness probe  
因此可以避免誤砍 pod 的狀況  

Startup probe 在 success 後便不會再 monitor   


## config sample  

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  template:
    spec:
      containers:
        - name: httpbin
          securityContext:
            {}
          image: "mccutchen/go-httpbin:latest"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /anything/livenessProbe
              port: http
          readinessProbe:
            httpGet:
              path: /anything/readinessProbe
              port: http
            periodSeconds: 10
          startupProbe:
            httpGet:
              path: /anything/startupProbe
              port: http
            periodSeconds: 10
```

probes 分成兩個部份 action 及 config  
範例定義了三種 probe  
並使用 httpGet 這個 action 來對 POD 做檢查  
periodSeconds 是 probe 運作的 config  

### action
三種 probs 支援的 action 都相同

支援的 action 如下  
- [exec](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#execaction-v1-core):   
  執行 command, 如果 return 0 代表 healthy, return non-zero 都是 unhealthy  
- [grpc](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#grpcaction-v1-core):  
  走 gRPC protocol 進行檢查  
- [httpGet](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#httpgetaction-v1-core):   
  走 http protocol 進行檢查, return status 200 ~ 399 都算 healthy  
- [tcpSocket](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.33/#tcpsocketaction-v1-core):  
  檢查 port 是否 linstening  


### config  

三種 probs 支援的 config 都相同  

- initialDelaySeconds:   
  當 pod running 後何時才開始運作 probe (要注意該設定是對所有 probe 都生效, 官方 doc/api doc 寫的並不同)  
  Defaults to 0 seconds. Minimum value is 0.  

- periodSeconds:  
  pod monitor 頻率 Default to 10 seconds. The minimum value is 1.  

- timeoutSeconds:   
  判斷 monitor timeout 時間 Defaults to 1 second. Minimum value is 1.  
- successThreshold:  
  monitor success 幾次判斷 pod healthy 的次數. Defaults to 1. Must be 1 for liveness and startup Probes. Minimum value is 1.  

- failureThreshold:  
  monitor fail 幾次判斷 pod unhealthy 的次數 Defaults to 3. Minimum value is 1.  

- terminationGracePeriodSeconds:  
  對於 livenessProbe, startupProbe 判斷 unhealthy 時 因為會將 pod 重起  
  可以設定一個 grace terminate 時間, 預設情況是用 pod 設定的 `terminationGracePeriodSeconds`  
  由 probes 的 restart 可以 override 此設定  
  比如說因為 high loading 造成的 unhealthy, 可能會允許更久的 grace terminate 時間  
  minimum value is 1.  


## test chart  
關於以上設定  可以使用 httpbin 調整 values.yaml 進行測試  

```bash
helm upgrade --install my-httpbin owan-charts/httpbin --version 0.1.7
```


---

probes 是 k8s 執行 workload 的重要功能  
可以避免 request 過早送入 pod 導致 fail (避免 rolling upgrade 時造成異常)  
也能藉此達成 auto recovery workload  
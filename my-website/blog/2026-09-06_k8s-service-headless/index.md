---
title: service-headless
tags: [k8s]
---
快速比較 k8s 中 headless service  差異   

<!-- truncate -->

docs: https://kubernetes.io/docs/concepts/services-networking/service/#headless-services  


headless 也就是不要 clusterIP 也因此等於不要 service 的 load-balancing 功能  

設定差異在 `.spec.clusterIP` 使用 "None"  

設定完後 CLUSTER-IP 就是空的  
```
❯ k get svc 
NAME               TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
httpbun            ClusterIP   10.43.61.13   <none>        80/TCP    71m
httpbun-headless   ClusterIP   None          <none>        80/TCP    9m43s

❯ k get pod -o wide 
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE      NOMINATED NODE   READINESS GATES
httpbun-58f7d4dcd9-2l2x5   1/1     Running   0          21m   10.42.1.8     ubuntu3   <none>           <none>
httpbun-58f7d4dcd9-d4cfd   1/1     Running   0          25m   10.42.3.57    ubuntu5   <none>           <none>
httpbun-58f7d4dcd9-hk57l   1/1     Running   0          21m   10.42.4.6     ubuntu4   <none>           <none>
httpbun-58f7d4dcd9-jtkk5   1/1     Running   0          21m   10.42.0.111   ubuntu1   <none>           <none>
httpbun-58f7d4dcd9-ttgjl   1/1     Running   0          21m   10.42.2.151   ubuntu2   <none>           <none>
```

兩者實際是 DNS 解析出來會不同  
非 headless 解析出來為 ClusterIP  
headless 解析出來為 pod ip  

```
root@ubuntu:/# dig httpbun.default.svc.cluster.local
httpbun.default.svc.cluster.local. 30 IN A      10.43.61.13

root@ubuntu:/# dig httpbun-headless.default.svc.cluster.local
httpbun-headless.default.svc.cluster.local. 30 IN A 10.42.4.6
httpbun-headless.default.svc.cluster.local. 30 IN A 10.42.3.57
httpbun-headless.default.svc.cluster.local. 30 IN A 10.42.1.8
httpbun-headless.default.svc.cluster.local. 30 IN A 10.42.2.151
httpbun-headless.default.svc.cluster.local. 30 IN A 10.42.0.111
```


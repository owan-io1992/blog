---
title: 介紹 metalLB
tags: [metalLB]
---

[metallb](https://metallb.io) 用於 k8s 中當作 loadbalancer 的 provider  
也是讓 service 可以夠過 mode: loadBalancer 來取得 external-IP  

支援兩種模式
- layer 2 mode  
- BGP mode 

## layer 2 mode  
也就是 VIP(virtual IP) 模式, 也就是在 node 上設定 sencondary IP  
使用上最簡單, 不須任何外部相依  
實際上由 metalLB 的 speaker pod 設定 VIP  

缺點如下:
- 不支援流量的負載平衡  
也就是 IP 在哪台 node 身上, 所有流量都往它跑  
另外 IP failover 也會有短暫的中斷  

- 不能支援跨網段  
顧名思義 layer 2  
如果有多網段的需求, 必須要不同網段的 node + 啟動對應的 speaker 在該 node 上  


## BGP mode 
顧名思義, 就是利用 BGP route 協定來宣告 IP  

由於 BGP 本來就有 ECMP(Equal-Cost Multi-Path) 功能  
因此可以提供流量的負載平衡  

實際上由 metalLB 的 frr-k8s pod 設定 VIP  

缺點: 必須要對應的 route 對接 BGP 協定  
需求相對較高  

另外如果你的 address pool 設定與 node 同網段  
建議採用 layer 2 mode  
詳細可以深入了解 BGP 的技術  

## 實操演練 L2 mode
ref. https://metallb.io/configuration/


1. install metalLB
```bash
helm repo add metallb https://metallb.github.io/metallb
helm upgrade --install metallb metallb/metallb -n metallb-system --create-namespace \
  --set=loadBalancerClass=metallb
```

2. 設定 IPAddressPool  
此設定先告知 metalLB 能使用哪些 IP  
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.56.50-192.168.56.60
```

3. 設定 L2Advertisement  
此設定告知 IPAddressPool 該使用 L2 模式來宣告  
```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: first-advertis
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
```

4. 套用 example service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: metallb-example
  annotations:
    # metallb.io/loadBalancerIPs: 192.168.56.55
    metallb.io/address-pool: first-pool
spec:
  loadBalancerClass: metallb
  selector:
    app: nginx
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80

---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx 
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```

5. 測試
```bash
❯ curl 192.168.56.50
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, nginx is successfully installed and working.
Further configuration is required for the web server, reverse proxy, 
API gateway, load balancer, content cache, or other features.</p>

<p>For online documentation and support please refer to
<a href="https://nginx.org/">nginx.org</a>.<br/>
To engage with the community please visit
<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
For enterprise grade support, professional services, additional 
security features and capabilities please refer to
<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```


## 其他問題

1. 能否限制 ip address 能夠被哪些 namespace or service 存取
實務上在 multi-tenancy 環境 metalLB 能夠設定 serviceAllocation 來解決此問題  
細節可以參考 API [ServiceAllocation](https://metallb.io/apis/#serviceallocation)

2. 可以單獨啟動 L2 or BGP mode ?  
預設情況 metalLB 會同時支援 L2 and BGP mode  
```bash
❯ k -n metallb-system top pod 
NAME                                            CPU(cores)   MEMORY(bytes)   
metallb-controller-d58c44d9d-vxpnl              1m           13Mi            
metallb-frr-k8s-bvkv2                           5m           54Mi            
metallb-frr-k8s-fnmqn                           4m           54Mi            
metallb-frr-k8s-kpz6r                           5m           54Mi            
metallb-frr-k8s-statuscleaner-8bf664555-lndf8   2m           12Mi            
metallb-speaker-82rxq                           4m           20Mi            
metallb-speaker-bm556                           4m           20Mi            
metallb-speaker-v9fcj                           4m           19Mi  
```

如果不想浪費 resource  
helm 可以調整 value  
```yaml
# L2 mode 開關
speaker:
  enabled: true

# BGP mode 開關
frrk8s:
  enabled: true
```



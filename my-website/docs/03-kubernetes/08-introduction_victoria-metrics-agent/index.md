---
tags: []
---
# introduction VictoriaMetrics Agent
[VictoriaMetrics Agent](https://docs.victoriametrics.com/victoriametrics/vmagent/)  
由 VictoriaMetrics 製作的 metric collector  
由於 VictoriaMetrics Agent(vmagent) 本身是 prometheus compatiable  
因此也能用於 mimir/prometheus/thanos  

簡單說明優點 就是 超省 resource

快速的 bencharmark 比較 vmagent 與 prometheus agent mode

兩邊皆蒐集同樣 metrics 來源
**version**
vmagent: v1.128.0
prometheus: v3.7.3

performance
```
kubectl top pod
NAME                                                CPU(cores)   MEMORY(bytes)   
prometheus-agent-server-b4bb8b5fb-5jhsw             24m          543Mi           
victoria-metrics-agent-6cc554f644-sf7h2             8m           115Mi 
```


由此可以看到 victoria-metrics-agent 帶來相當良好的 resource 使用率  
  
## conclusion

prometheus 因為不支援 HA / prformance 低下  
因此即便 prometheus protocol 是目前 monitor 的首選  
但 prometheus 卻不是 monitor system 的首選  
是相當奇妙的狀況呢  
---
tags: []
---
# benchmark log collector for loki - fluent-bit, alloy, promtail
自從 grafana 決定啟動 alloy 這個計畫後  
一直想測試哪個 log collector 有最好的 performance  
以下簡單測試  

## test version 
fluent-bit: v4.1.1  
alloy: v1.11.3  
promtail: v3.5.7  


## test config 

### fluent-bit
```
[SERVICE]
    Daemon              Off
    Flush               1
    Log_Level           error
    Parsers_File        /fluent-bit/etc/parsers.conf
    Parsers_File        /fluent-bit/etc/conf/custom_parsers.conf
    HTTP_Server         On
    json.escape_unicode Off
    HTTP_Listen         0.0.0.0
    HTTP_Port           2020
    Health_Check        On

[INPUT]
    Name                tail
    Path                /var/log/containers/*.log
    multiline.parser    docker, cri
    Tag                 kube.*
    Mem_Buf_Limit       5MB
    Skip_Long_Lines     On

[FILTER]
    Name                kubernetes
    Match               kube.*
    Merge_Log           On
    Keep_Log            Off
    K8S-Logging.Parser  On
    K8S-Logging.Exclude On

[OUTPUT]
    Name                loki
    Match               kube.*
    Host                loki-write.monitor.svc
    Port                3100
    Tenant_ID           default
    TLS                 Off
```


### alloy
```
discovery.kubernetes "pods" {
    role = "pod"
}

loki.source.kubernetes "pods" {
    targets    = discovery.kubernetes.pods.targets
    forward_to = [loki.write.local.receiver]
}

loki.write "local" {
    endpoint {
    url = "http://loki-write.monitor.svc:3100/loki/api/v1/push"
    tenant_id = "alloy"
    }
}
```

### promtail
(scrape_configs is helm chart default value)
```
server:
  log_level: info
  log_format: logfmt
  http_listen_port: 3101
  

clients:
  - tenant_id: default
    url: http://loki-write.monitor.svc:3100/loki/api/v1/push

positions:
  filename: /run/promtail/positions.yaml

scrape_configs:
  # See also https://github.com/grafana/loki/blob/master/production/ksonnet/promtail/scrape_config.libsonnet for reference
  - job_name: kubernetes-pods
    pipeline_stages:
      - cri: {}
      - labeldrop:
        - filename
        - job
        - node_name
        - container
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels:
          - __meta_kubernetes_pod_controller_name
        regex: ([0-9a-z-.]+?)(-[0-9a-f]{8,10})?
        action: replace
        target_label: __tmp_controller_name
      - source_labels:
          - __meta_kubernetes_pod_label_app_kubernetes_io_name
          - __meta_kubernetes_pod_label_app
          - __tmp_controller_name
          - __meta_kubernetes_pod_name
        regex: ^;*([^;]+)(;.*)?$
        action: replace
        target_label: app
      - source_labels:
          - __meta_kubernetes_pod_label_app_kubernetes_io_instance
          - __meta_kubernetes_pod_label_instance
        regex: ^;*([^;]+)(;.*)?$
        action: replace
        target_label: instance
      - source_labels:
          - __meta_kubernetes_pod_label_app_kubernetes_io_component
          - __meta_kubernetes_pod_label_component
        regex: ^;*([^;]+)(;.*)?$
        action: replace
        target_label: component
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: node_name
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        replacement: $1
        separator: /
        source_labels:
        - namespace
        - app
        target_label: job
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_container_name
        target_label: container
      - action: replace
        replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_uid
        - __meta_kubernetes_pod_container_name
        target_label: __path__
      - action: replace
        regex: true/(.*)
        replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
        - __meta_kubernetes_pod_annotationpresent_kubernetes_io_config_hash
        - __meta_kubernetes_pod_annotation_kubernetes_io_config_hash
        - __meta_kubernetes_pod_container_name
        target_label: __path__
  
  

limits_config:
  

tracing:
  enabled: false

```

## test method
use script generate log   
all collector collect same log source  

all collector running in same node 
## test result 
```
$ kubectl top pod
NAME                                                    CPU(cores)   MEMORY(bytes)   
alloy-r8ztr                                             47m          136Mi           
fluent-bit-ggmmt                                        114m         16Mi            
promtail-lmx5q                                          73m          72Mi   
```


## conclusion
alloy: 與前身 grafana agent 似乎有同樣的問題, 使用相當多的 memory  
但其支援 metrics/log/trace 之後進一部測試功能開的越多時  
是否會使用更多 resource?  
以及處理 metrics/trace 效果如何?  
是否能剩任 all-in-one collector?  

fluent-bit: 出乎意料的使用相當高的 cpu, memory 表現亮眼  
也能 collect metrics/trace, 但畢竟術業有專攻, 以前測試並不滿意  
單純 collect log 很好用  

promtail: 表現平衡, 但僅限蒐集 log  
官方已經正式 annonce 要轉移至 alloy  
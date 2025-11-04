---
date: 2025-11-04T06:15:00  
draft: false
tags: []
title: "k8s prometheus annotations scrape config"
---

prometheus 在 k8s 環境中  
利用 [kubernetes_sd_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config) 
可以自動發現 meta labels  
可以用於動態設定 scrape target  
因此在 k8s 環境中 prometheus 的 scrape config 幾乎是固定的  

如果使用 prometheus helm chart 安裝 prometheus 時, 已經寫好 scrape config  
readme 有簡短的說明 [Scraping Pod Metrics via Annotations](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#scraping-pod-metrics-via-annotations)


簡單來說就是只要加上 pod annotations 即可被 prometheus 監控  

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/path: /metrics
    prometheus.io/port: "8080"
```

然而這說明實在太過簡單  
實際上官方提供的 scrape config 可以達成的功能並不只這樣  

實際了解 [vaule file](https://raw.githubusercontent.com/prometheus-community/helm-charts/refs/heads/main/charts/prometheus/values.yaml)  
可以了解 annotations 設定方式也支援 service endpoint  
將 annotations 設定在 service, 會自動對該 service 下所有 endpoint target scrape metrics  

以下詳細說明能支援的 annotations config  

## annotations config format
以下為支援的 annotations 格式

```bash
# Scrape target: 兩種設定，擇一使用
## interval 1m, timeout 10s
prometheus.io/scrape: "true"
## interval 5m, timeout 30s
prometheus.io/scrape_slow: "true"

# (Optional) 若 metrics 路徑不是 `/metrics`，請覆寫此設定。
prometheus.io/path: /metrics

# (Optional) Scrape target: 使用指定 port，而非預設的 `9102`。
prometheus.io/port: "9102"

# (Optional) 若 metrics endpoint 需安全連線，請設定為 `https`。
prometheus.io/scheme: "http"

# (Optional) 若 metrics endpoint 使用參數，可在此設定。
prometheus.io/param_<key>: <value>
```

## example annotations config
以下提供範例
如果設定  
```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/path: "/metrics_hello"
    prometheus.io/port: "9527"
    prometheus.io/scheme: "https"
    prometheus.io/param_token: "mysecrettoken"
```

那麼抓取 URL 會變成 https://<pod_ip>:9527/metrics_hello?token=mysecrettoken  

## enahance annotations scrape config

既然 annotations 可以動態調整，
同理也能用它來調整 scrape interval。

在 charts values 的 scrape job_name: 'kubernetes-pods' 中加入這段 `relabel_configs`：
```yaml
- source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_interval]
  action: replace
  target_label: __scrape_interval__
  regex: (.+)
```

接著設定 annotations：
```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/interval: "15s"
```

如此一來，即可單獨調整每個 target 的 scrape interval。

## Conclusion  
透過 annotations 設定 scrape 相當簡易，無需像 Prometheus Operator 那樣新增 manifest。  
這表示在使用各種 Helm charts 時，基本上都能直接設定監控，避免多出一個不必要的 `PodMonitors` manifest。  
這方式也是目前大部分 exporter chart 的預設 monitor 方式  
[prometheus-node-exporter](https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-node-exporter/values.yaml#L146)  

然而，annotations 不適合設定過於複雜的內容，因此與 Prometheus Operator 搭配使用會是更合理的選擇。

---
date: 2025-11-02T06:12:00  
draft: false
tags: []
title: "VictoriaMetrics Operator 簡介：無痛轉換 Prometheus Operator"
---

在之前的文章中，我們提到了 `VictoriaMetrics agent` (`vmagent`) 作為一個高效率的指標收集器。與 `Prometheus Operator` 相對應，VictoriaMetrics 也提供了 `VictoriaMetrics Operator` (`vmoperator`)。`vmoperator` 的一個主要優勢是它與 `Prometheus Operator` 的 `ServiceMonitor` 和 `PodMonitor` CRD 完全相容，這使得從 Prometheus 生態系統的轉換過程非常順暢。

## Getting Started

首先，我們需要安裝 `prometheus-operator`，因為 `vmoperator` 會使用到它定義的 CRD。

```shell
LATEST=$(curl -s https://api.github.com/repos/prometheus-operator/prometheus-operator/releases/latest | jq -cr .tag_name)
curl -sL https://github.com/prometheus-operator/prometheus-operator/releases/download/${LATEST}/bundle.yaml | kubectl create -f -
```

接著，透過 Helm 安裝 `vmoperator`：

```shell
helm repo add vm https://victoriametrics.github.io/helm-charts/
helm repo update
helm install vmo vm/victoria-metrics-operator -n victoriametrics
```

### 部署範例應用程式

為了演示 `vmoperator` 的監控能力，我們部署一個簡單的應用程式。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: example-app
  template:
    metadata:
      labels:
        app: example-app
    spec:
      containers:
      - name: example-app
        image: docker.io/infrastructureascode/hello-world:2.4.0
        ports:
        - name: web
          containerPort: 8080
```

### 建立 PodMonitor

`vmoperator` 可以直接使用 `PodMonitor` 來發現並抓取 Pod 的指標。

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: example-app
  labels:
    team: frontend
spec:
  selector:
    matchLabels:
      app: example-app
  podMetricsEndpoints:
  - port: web
```

### 建立 VMAgent

最後，我們建立一個 `VMAgent` 實例，它會根據 `PodMonitor` 的定義來抓取指標，並將其發送到遠端儲存。

```yaml
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMAgent
metadata:
  name: example-vmagent
spec:
  # selectAllByDefault: true 會讓 VMAgent 抓取所有命名空間中的 PodMonitors 和 ServiceMonitors
  selectAllByDefault: true
  remoteWrite:
    - url: "http://your-remote-storage:8080/api/v1/push"
  extraArgs:
    remoteWrite.headers: "X-Scope-OrgID:vmagent"
    remoteWrite.forcePromProto: "true"
```

## Conclusion

通過以上步驟，我們可以看到 `vmoperator` 能夠無縫接管 `Prometheus Operator` 的監控定義（如 `PodMonitor` 和 `ServiceMonitor`）。

這意味著您可以在不更改現有監控配置的情況下，輕鬆地將指標收集的重任交給 `vmagent`。`vmagent` 以其更低的資源消耗和更高的效率著稱，這將有助於大幅節省 Kubernetes 叢集的資源使用，同時維持強大的監控能力。
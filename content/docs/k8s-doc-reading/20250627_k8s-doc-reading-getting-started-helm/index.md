---
date: 2025-06-27T11:53:00  
draft: false
tags:
- k8s-reading
title: "k8s doc reading: Concepts: Getting started - helm"
weight: 7
---
![alt](images/banner.png)  

<!--more-->

在 getting start 我們安裝了 k3s  

以及使用了 kubectl 去新增 deplyment & service  
可是這其實相當難以管理眾多的 manifest  
因此 helm 這個工具就誕生了  
> 同類型的工具很多, k8s 官方也提供 Kustomize 
> 但目前來說 helm 是主流, 所以建議大家學習 helm  


## install helm

Helm 官方提供了很多安裝方式, 其中最簡單的是 script 安裝

```bash
https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```


## helm introduction

Helm 是 Kubernetes 的 manifest(yaml) 管理器。把一堆 k8s manifest 包裝成一個 chart
透過 chart 我們可以很輕鬆地安裝、升級、刪除 k8s 上的應用程式

主要有幾個核心概念
- **Chart**: Helm 的打包格式, 包含了一組 k8s manifest 的模板
- **Release**: 在 k8s 集群上運行的 chart 的一個實例
- **Repository**: 用來存放和分享 chart 的地方

## getting start helm chart

我們來試著安裝一個 nginx chart  
首先, 我們需要新增一個 repository(使用人家寫好的 chart)  

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

搜尋看看有沒有 nginx chart 可以使用   
```bash
$ helm search repo nginx
NAME                                            CHART VERSION   APP VERSION     DESCRIPTION                                       
bitnami/nginx                                   20.0.7          1.28.0          NGINX Open Source is a web server that can be a...

```

最後, 我們安裝 nginx  
```bash
helm install my-nginx bitnami/nginx
```

透過 `kubectl get pod` 可以看到 nginx 已經被安裝上去了  


接著我們把 chart download 下來看看裡面  
```bash
helm pull bitnami/nginx --untar
```

結構
```bash 
$ tree
.
├── Chart.lock
├── charts
│   └── common
│       ├── Chart.yaml
│       ├── README.md
│       ├── templates
│       │   ├── _affinities.tpl
│       │   ├── _capabilities.tpl
│       │   ├── _compatibility.tpl
│       │   ├── _errors.tpl
│       │   ├── _images.tpl
│       │   ├── _ingress.tpl
│       │   ├── _labels.tpl
│       │   ├── _names.tpl
│       │   ├── _resources.tpl
│       │   ├── _secrets.tpl
│       │   ├── _storage.tpl
│       │   ├── _tplvalues.tpl
│       │   ├── _utils.tpl
│       │   ├── validations
│       │   │   ├── _cassandra.tpl
│       │   │   ├── _mariadb.tpl
│       │   │   ├── _mongodb.tpl
│       │   │   ├── _mysql.tpl
│       │   │   ├── _postgresql.tpl
│       │   │   ├── _redis.tpl
│       │   │   └── _validations.tpl
│       │   └── _warnings.tpl
│       └── values.yaml
├── Chart.yaml
├── README.md
├── templates
│   ├── deployment.yaml
│   ├── extra-list.yaml
│   ├── health-ingress.yaml
│   ├── _helpers.tpl
│   ├── hpa.yaml
│   ├── ingress-tls-secret.yaml
│   ├── ingress.yaml
│   ├── networkpolicy.yaml
│   ├── NOTES.txt
│   ├── pdb.yaml
│   ├── prometheusrules.yaml
│   ├── server-block-configmap.yaml
│   ├── serviceaccount.yaml
│   ├── servicemonitor.yaml
│   ├── stream-server-block-configmap.yaml
│   ├── svc.yaml
│   └── tls-secret.yaml
├── values.schema.json
└── values.yaml
```

charts/: 用於存放此 chart 依賴的其他 chart (subcharts) 
Chart.lock: 用於鎖定 chart 依賴的 subcharts 的版本，確保每次部署的一致性  
Chart.yaml: 包含了 chart 的元數據，例如 chart 名稱、版本、描述等  
README.md: 提供 chart 的人類可讀的說明文件   
templates/: 存放 Kubernetes 資源的模板文件。Helm 會將這裡的模板與 `values.yaml` 的值結合，生成最終的 Kubernetes manifest  
values.yaml: 提供 chart 的默認配置值。用戶可以覆蓋這些值來自定義 chart 的部署  

---

以上是 helm 的快速入門  
如果一個完整的 app 需要 deploymnet,service,...etc  
而他相依的 DB 也需要 deploymnet,service,...etc  
會有非常多的 yaml file 要管理  
helm 會包成一個 chart  
並利用 template 機制產生 yaml  
讓管理 app 所有 yaml 簡單的多  
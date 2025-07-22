---
date: 2025-07-21T02:48:00  
draft: false
tags: []
title: "introduction istio Ambient Mode"
---

<!--more-->

https://istio.io/latest/docs/

## install
```bash
# install cli
mise use linkerd@edge-25.7.4

# install gateway api
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

# pre check
linkerd check --pre

# install linkerd
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
```


---
date: 2025-07-21T02:48:00  
draft: false
tags: []
title: "introduction istio sidecar Mode"
---

<!--more-->

https://istio.io/latest/docs/

## install
https://istio.io/latest/docs/setup/getting-started/

```bash
# install cli
mise use -g istioctl@1.26.2


# install gateway api
#kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
#  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

# pre check
istioctl version

# install istio
istioctl install -f samples/bookinfo/demo-profile-no-gateways.yaml -y
```




# Deploy a sample application
https://istio.io/latest/docs/ambient/getting-started/deploy-sample-app/

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/bookinfo/platform/kube/bookinfo-versions.yaml

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/bookinfo/gateway-api/bookinfo-gateway.yaml
kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default

# access service
kubectl port-forward svc/bookinfo-gateway-istio 8080:80
http://localhost:8080/productpage
```


# Secure and visualize the application

Add Bookinfo to the mesh
```bash
kubectl label namespace default istio.io/dataplane-mode=ambient
```

Visualize the application and metrics
```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/addons/kiali.yaml
```

??? fail for waypoint 
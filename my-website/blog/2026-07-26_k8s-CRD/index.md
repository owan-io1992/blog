---
title: 介紹 k8s 中 CRD 用途  
tags: [CRD,k8s]
---
  ____ ____  ____  
 / ___|  _ \|  _ \ 
| |   | |_) | | | |
| |___|  _ <| |_| |
 \____|_| \_\____/ 

<!-- truncate -->

快速記錄下 k8s 中使用 CRD 的小技巧  
CRD 全名是 [customresourcedefinitions](https://kubernetes.io/docs/reference/kubernetes-api/apiextensions/custom-resource-definition-v1/)  

用途就是擴充 k8s 的 API  

已目前最常用的來說  應該是 [gateway API](https://gateway-api.sigs.k8s.io/guides/getting-started/introduction/#installing-gateway-api)  

安裝 gateway CRD command  
```bash
$ kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml
customresourcedefinition.apiextensions.k8s.io/backendtlspolicies.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/grpcroutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/listenersets.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/referencegrants.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/tcproutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/tlsroutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/udproutes.gateway.networking.k8s.io serverside-applied
validatingadmissionpolicy.admissionregistration.k8s.io/safe-upgrades.gateway.networking.k8s.io serverside-applied
validatingadmissionpolicybinding.admissionregistration.k8s.io/safe-upgrades.gateway.networking.k8s.io serverside-applied
```

檢查已安裝的 CRD  
```bash
$ k api-resources | grep gate
NAME                                SHORTNAMES         APIVERSION                                  NAMESPACED   KIND
backendtlspolicies                  btlspolicy         gateway.networking.k8s.io/v1                true         BackendTLSPolicy
gatewayclasses                      gc                 gateway.networking.k8s.io/v1                false        GatewayClass
gateways                            gtw                gateway.networking.k8s.io/v1                true         Gateway
grpcroutes                                             gateway.networking.k8s.io/v1                true         GRPCRoute
httproutes                                             gateway.networking.k8s.io/v1                true         HTTPRoute
listenersets                        lset               gateway.networking.k8s.io/v1                true         ListenerSet
referencegrants                     refgrant           gateway.networking.k8s.io/v1                true         ReferenceGrant
tcproutes                                              gateway.networking.k8s.io/v1                true         TCPRoute
tlsroutes                                              gateway.networking.k8s.io/v1                true         TLSRoute
udproutes                                              gateway.networking.k8s.io/v1                true         UDPRoute

# or 
$ k get crd | grep gate
NAME                                                      CREATED AT
backendtlspolicies.gateway.networking.k8s.io              2026-07-26T07:55:02Z
gatewayclasses.gateway.networking.k8s.io                  2026-07-26T07:55:02Z
gateways.gateway.networking.k8s.io                        2026-07-26T07:55:02Z
grpcroutes.gateway.networking.k8s.io                      2026-07-26T07:55:03Z
httproutes.gateway.networking.k8s.io                      2026-07-26T07:55:04Z
listenersets.gateway.networking.k8s.io                    2026-07-26T07:55:04Z
referencegrants.gateway.networking.k8s.io                 2026-07-26T07:55:04Z
tcproutes.gateway.networking.k8s.io                       2026-07-26T07:55:05Z
tlsroutes.gateway.networking.k8s.io                       2026-07-26T07:55:05Z
udproutes.gateway.networking.k8s.io                       2026-07-26T07:55:06Z
```

在 api-resources 只能看到 major 版本  
可以使用 describe 查看詳細版本  
```bash
$ k get crd gateways.gateway.networking.k8s.io -o jsonpath='{.metadata.annotations}' | jq 
{
  "api-approved.kubernetes.io": "https://github.com/kubernetes-sigs/gateway-api/pull/4530",
  "gateway.networking.k8s.io/bundle-version": "v1.6.1",
  "gateway.networking.k8s.io/channel": "standard"
}
```


至於自定義 CRD  
可以使用 [operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) 製作  
未來有實作時, 再做分享  
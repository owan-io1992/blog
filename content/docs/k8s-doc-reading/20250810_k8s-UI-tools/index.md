---
date: 2025-07-08T06:06:00
draft: false
tags:
- k8s-reading
title: "kubernetes UI tools"
weight: 30
---
![alt](images/banner.png)  

<!--more-->

這篇不是官方 doc  
而是整理的 UI 工具
對於不熟悉的人, 圖形化是非常友善的工具  

## dashboard
[doc link](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)   

kubernetes 官方做的 dashboard  
但功能非常陽春, 根本上真的就只是一個 dashboard   
個人是裝過一次就沒再使用了  
還是習慣使用 kubectl, 快又直接  

```bash
# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
```

create account
```bash
tee dashboard-adminuser.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

tee dashboard-ClusterRole.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

kubectl apply -f dashboard-ClusterRole.yaml
kubectl apply -f dashboard-adminuser.yaml
kubectl -n kubernetes-dashboard create token admin-user
```

access
```bash
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443

# open
https://localhost:8443
```

## Lens

official site: [Lens](https://k8slens.dev)
安裝就略過, 僅提供介紹  

Lens 是一款強大的 Kubernetes IDE，它以本地應用程式的形式運行在開發者的電腦上（支援 Mac, Windows, Linux）。它不僅僅是一個儀表板，更是一個完整的 Kubernetes 開發與維運工作站。

**主要特點：**
- **多叢集管理**：可以輕鬆地在多個 Kubernetes 叢集之間切換，並在統一的介面中管理它們。
- **豐富的視覺化**：提供即時的資源狀態、日誌串流 (log streaming)、資源拓撲圖和效能指標。
- **上下文感知終端**：內建終端機，會自動配置好 `kubectl` 的上下文，無需手動切換。
- **Helm Chart 管理**：可以直接在 UI 中瀏覽、安裝和管理 Helm charts。
- **擴充性**：支援擴充功能 (Extensions)，可以整合 Prometheus、Jaeger 等其他雲原生工具。

**優點：**
- 對開發者和維運人員非常友好，大幅降低了 `kubectl` 的學習曲線。
- 視覺化做得非常出色，對於理解複雜的 K8s 物件關係非常有幫助。
- 錯誤排查效率高，可以直接在 UI 上查看日誌、進入 Pod 的 shell。

**缺點：**
- 雖然有免費的社群版 (Lens Desktop)，但一些進階功能（如團隊協作、SSO）需要付費訂閱 (Lens Pro)。
- 作為本地應用程式，會消耗本機的記憶體和 CPU 資源。

## rancher

official site: [Rancher](https://www.rancher.com/)
安裝就略過, 僅提供介紹  

Rancher 是一個開源的、完整的企業級 Kubernetes 管理平台。它不僅僅是一個 UI 工具，更是一個多叢集、多雲的 Kubernetes-as-a-Service 解決方案。它由 SUSE 公司支援。

**主要特點：**
- **集中式叢集管理**：可以從一個中央控制台佈建、管理和監控位於任何地方的 Kubernetes 叢集（包括公有雲、私有雲、邊緣節點）。
- **統一的認證與權限管理**：整合了 Active Directory, LDAP, SAML 等，可以對所有叢集進行統一的 RBAC 策略管理。
- **豐富的應用程式目錄**：內建了基於 Helm 的應用程式商店，可以一鍵部署常用的應用程式。
- **強化的安全性和策略管理**：提供 CIS 安全掃描、OPA Gatekeeper 整合等功能。
- **完整的維運工具鏈**：整合了監控 (Prometheus)、日誌 (Fluentd)、服務網格 (Istio) 等工具。

**優點：**
- 提供了從底層基礎設施到應用程式部署的端到端解決方案。
- 非常適合需要管理大量、分散式 Kubernetes 叢集的企業。
- 安全性和多租戶管理功能非常強大。

**缺點：**
- 相較於 Lens，Rancher 本身是一個較為龐大的系統，需要獨立的伺服器來運行其管理平面。
- 對於小型團隊或個人使用者來說，部署和維護 Rancher 可能會顯得過於複雜。

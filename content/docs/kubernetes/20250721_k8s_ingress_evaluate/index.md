---
date: 2025-07-21T00:38:00  
draft: false
tags: []
title: "k8s ingress evaluate"
---

<!--more-->


* [NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/)
* [caddy server](https://github.com/caddyserver/ingress)
* [HAProxy Kubernetes Ingress Controller](https://www.haproxy.com/documentation/kubernetes-ingress/)
* [Emissary-ingress](https://www.getambassador.io/docs)
* [Envoy Gateway](https://gateway.envoyproxy.io/docs/)
* [contour](https://projectcontour.io/docs/main/)
* [Kong Gateway](https://developer.konghq.com/gateway/)
* [APISIX Ingress Controller](https://apisix.apache.org/docs/ingress-controller/getting-started/)

## fast evaluate by ai

### gemini pro 2.5  
with google and URL context

| Ingress Controller | 優點 | 缺點 |
| :--- | :--- | :--- |
| **NGINX Ingress Controller** | - 非常成熟、穩定，社群廣大且文件齊全。<br>- 效能可靠，廣泛應用於生產環境。<br>- 設定靈活，可使用 Lua 腳本擴充。 | - 新增或修改設定時需要重載 (reload)，可能影響線上流量。<br>- 擴充性較弱，複雜的流量管理需求設定較為繁瑣。 |
| **Caddy Ingress Controller** | - 設定簡單易懂。<br>- 自動化 HTTPS，自動申請與續訂 Let's Encrypt 憑證。<br>- 以 Go 語言編寫，易於透過插件擴充。 | - 作為 Ingress Controller 的實現尚不成熟，功能較基礎。<br>- 官方團隊對 Kubernetes 專業知識有限，主要依賴社群維護。<br>- 相比主流方案，文件和社群討論較少。 |
| **HAProxy Kubernetes Ingress Controller** | - 高效能、可靠性高，以其負載平衡技術聞名。<br>- 提供進階的流量管理與豐富的負載平衡演算法。<br>- 設定可平滑更新，不中斷流量。 | - 相較於 NGINX，學習曲線可能稍高。 |
| **Emissary-ingress (Ambassador)** | - 基於 Envoy，功能豐富，特別適合微服務架構。<br>- 可與多種服務網格 (Service Mesh) 解決方案整合。<br>- 透過 CRD (Custom Resource Definitions) 進行設定，與 Kubernetes 原生整合度高。 | - 相對複雜，學習成本較高。 |
| **Envoy Gateway** | - 基於高效能的 Envoy 代理，可處理高流量。<br>- 擴充性強，支援自訂過濾器。<br>- 與 Kubernetes Gateway API 緊密整合，設定簡化。<br>- 專為「南北向」流量設計，並可與服務網格整合。 | - 學習曲線陡峭，設定門檻高。<br>- 專案相對較新，仍在發展中。 |
| **Contour** | - 基於 Envoy，高效能、低延遲。<br>- 支援 HTTP/2 與 gRPC。<br>- 透過自訂的 HTTPProxy CRD 提供比標準 Ingress 更進階的功能。<br>- 輕量級，適合現代化的微服務架構。 | - 相較於一些老牌 Ingress，社群規模較小。 |
| **Kong Gateway** | - 作為 API 閘道器功能強大，擁有豐富的插件生態系。<br>- 透過 CRD 進行動態設定。<br>- 提供社群版與企業版。 | - 核心功能專注於 API 管理，作為單純的 Ingress Controller 可能過於複雜。 |
| **APISIX Ingress Controller** | - 基於高效能的 APISIX，具備動態、無需重載的特性。<br>- 插件生態豐富，支援多語言開發插件 (Lua, Go, Python, Java 等)。<br>- 支援 Gateway API、CRD 等多種設定方式。<br>- 控制平面與資料平面分離，提升安全性。 | - 相較於 NGINX，專案較新，在某些企業環境的採用案例可能較少。 |



* NGINX Ingress Controller: 作為最廣泛使用的 Ingress 之一，它非常穩定且擁有龐大的社群支援。[1] 如果您的需求相對單純，且團隊對 NGINX 已有一定熟悉度，這會是一個非常可靠的選擇。[13] 但它的主要缺點是每次更新設定都需要重載，且在面對複雜的路由與流量治理需求時，擴充性不如基於 Envoy 的新一代 Ingress。[3][4]  
* Caddy Ingress Controller: Caddy 最大的亮點是其極簡的設定和自動化的 HTTPS 功能。[6][7] 對於中小型專案或個人開發者來說，可以大幅簡化憑證管理的複雜度。[8] 然而，它的 Ingress Controller 實現還不夠成熟，缺少許多進階功能，且主要由社群驅動，企業級支援較少。[10]  
* HAProxy Kubernetes Ingress Controller: HAProxy 以其卓越的效能和可靠的負載平衡能力著稱。[1][11] 它支援平滑的設定更新，不會造成流量中斷，並提供比 NGINX 更多* 的負載平衡演算法。[1][12]  
* Emissary-ingress (Ambassador): 它是一個基於 Envoy 的 Kubernetes 原生 API 閘道器。[12][13] 功能非常豐富，特別適合需要進階流量管理和微服務整合的場景。* [12]  
* Envoy Gateway: 這是一個專門為 Kubernetes 設計的、實現了 Gateway API 標準的專案。[15] 它旨在簡化將 Envoy 作為 Ingress Gateway 的複雜度，提供強大的效能和擴* 充性，同時讓應用程式開發者和基礎架構管理者能各司其職。[15]  
* Contour: 同樣基於 Envoy，  Contour 的設計目標是輕量級和高效能。[1][13] 它透過自家的 CRD (HTTPProxy) 提供了比 Kubernetes 標準 Ingress 更強大且安全的路由功能，特別適合現代雲原生應用。  
* Kong Gateway: Kong 的核心是一個功能強大的 API 閘道器，擁有非常豐富的插件生態，可以處理認證、監控、流量控制等複雜需求。[12] 如果您的主要場景是 API 管理，Kong 會* 是很棒的選擇。  
* APISIX Ingress Controller: APISIX 是一個高效能的 API 閘道器，其 Ingress Controller 繼承了這個優點。 最大的特色是完全動態的設定，無需重載即可生效，並且支援多種語言編寫插件，擴充性極佳。[3] 它也積極擁抱 Gateway API 標準，是一個功能非常全面的現代化選擇。  
- Sources
- help
- medium.com
- hypermode.com
- nerd-corner.com
- caddy.community
- markheath.net
- api7.ai
- dev.to
- api7.ai
- apache.org
- medium.com
- tetrate.io
- zuplo.com
- jimmysong.io
- reddit.com
- solo.io

### claude sonnet 4

**綜合比較表格**  
| Ingress Controller | 效能評級 | 學習難度 | 社群支援 | 企業級功能 | 資源消耗 | 主要特色 |
|-------------------|--------|---------|---------|-----------|---------|----------|
| **NGINX** | ⭐⭐⭐⭐ | 中等 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 中等 | 最成熟穩定，社群最大 |
| **Caddy** | ⭐⭐⭐ | 簡單 | ⭐⭐ | ⭐⭐ | 低 | 自動 HTTPS，配置最簡 |
| **HAProxy** | ⭐⭐⭐⭐⭐ | 困難 | ⭐⭐⭐ | ⭐⭐⭐⭐ | 中等 | 負載均衡效能最佳 |
| **Emissary** | ⭐⭐⭐ | 困難 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 高 | 完整 API Gateway |
| **Envoy Gateway** | ⭐⭐⭐⭐ | 困難 | ⭐⭐⭐ | ⭐⭐⭐ | 中等 | 支援 Gateway API |
| **Contour** | ⭐⭐⭐⭐ | 中等 | ⭐⭐⭐ | ⭐⭐⭐ | 中等 | VMware 企業支援 |
| **Kong** | ⭐⭐⭐ | 困難 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 高 | 完整 API 管理平台 |
| **APISIX** | ⭐⭐⭐⭐ | 中等 | ⭐⭐ | ⭐⭐⭐ | 中等 | 現代化架構，豐富插件 |

**功能特性比較表格**  
| 功能特性 | NGINX | Caddy | HAProxy | Emissary | Envoy GW | Contour | Kong | APISIX |
|---------|-------|-------|---------|----------|----------|---------|------|--------|
| **自動 HTTPS** | 🔶 手動 | ✅ 自動 | 🔶 手動 | ✅ 支援 | ✅ 支援 | ✅ 支援 | ✅ 支援 | ✅ 支援 |
| **負載均衡算法** | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **TCP/UDP 支援** | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **插件生態** | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **監控指標** | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **金絲雀部署** | 🔶 複雜 | ❌ | 🔶 複雜 | ✅ 簡單 | ✅ 支援 | ✅ 支援 | ✅ 簡單 | ✅ 支援 |
| **gRPC 支援** | ✅ | ✅ | 🔶 限制 | ✅ | ✅ | ✅ | ✅ | ✅ |
| **WebSocket** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### chatGPT 4o


| 名稱                     | 優點                                                                 | 缺點                                                                 |
|--------------------------|----------------------------------------------------------------------|----------------------------------------------------------------------|
| **NGINX Ingress**        | - 穩定成熟<br>- 文件完整<br>- 社群活躍<br>- 高度可自定義                     | - 設定較複雜<br>- Annotation 易混亂<br>- 高併發效能有限             |
| **Caddy Server**         | - 自動 TLS 憑證<br>- 配置簡單直覺<br>- 輕量化適合簡單場景                   | - 功能尚未完整<br>- 社群較小<br>- 缺乏進階功能                       |
| **HAProxy Ingress**      | - 高效能低延遲<br>- 支援 TCP/TLS passthrough<br>- 穩定性強                  | - 學習曲線高<br>- Kubernetes 文件較少<br>- 可觀察性整合不足         |
| **Emissary (Ambassador)**| - 基於 Envoy<br>- gRPC/WebSocket 支援良好<br>- GitOps 友善<br>- 可擴充性高  | - 資源使用高<br>- YAML 較複雜<br>- 商業版功能限制                   |
| **Envoy Gateway**        | - 支援 Gateway API<br>- 現代設計<br>- 原生支援 gRPC/TLS/觀察性               | - 尚在發展中<br>- 文件尚未齊備<br>- 社群成熟度較低                  |
| **Contour**              | - 基於 Envoy<br>- 支援 Gateway API 與 HTTPProxy<br>- 與 cert-manager 整合佳 | - 小眾社群<br>- 非標準 annotation<br>- 缺少內建進階功能              |
| **Kong Gateway**         | - 插件系統豐富<br>- 支援 API 管理功能（OAuth2、限速）<br>- 雲原生整合佳      | - 較重、複雜<br>- 商業功能需付費<br>- 小型專案可能過度               |
| **APISIX Ingress**       | - Plugin 架構<br>- 動態配置能力佳<br>- 支援 gRPC/JWT/限速                   | - 文件不足<br>- 社群規模較小<br>- 整合還在建構中                    |


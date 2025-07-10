---
date: 2025-06-13T00:00:00
draft: false
tags:
- k3s
title: k3s install advance 1 
---
![alt](images/banner.png)

<!--more-->

K3s 是一個輕量級的 Kubernetes 發行版，專為邊緣運算、物聯網和資源受限的環境設計。儘管其設計輕巧，K3s 依然提供了強大的功能，足以應對許多生產環境的需求。本篇文章將深入探討 K3s 的進階配置，特別是如何利用安裝腳本參數來客製化部署，以及如何建立一個高可用性 (High Availability, HA) 的 K3s 叢集。

透過本文，您將學習到：
*   K3s 安裝腳本的常用參數及其應用場景。
*   如何精確控制 K3s 的版本。
*   如何配置 K3s 叢集中的伺服器 (Server) 和代理 (Agent) 節點。
*   K3s 內建服務負載平衡器 (Service Load Balancer) 和 Ingress Controller 的管理。
*   如何利用嵌入式 etcd 實現 K3s 叢集的高可用性。
*   透過 Keepalived 建立虛擬 IP (Virtual IP, VIP) 以增強 API Server 的穩定性。

讓我們開始探索 K3s 的進階世界吧！

## 安裝腳本參數 (Args in Install Script)
K3s 的安裝過程極具彈性，主要透過 `curl -sfL https://get.k3s.io | sh -s -` 這條命令，並搭配環境變數或直接傳遞參數給 `sh -s -` 來實現客製化。這些參數允許您在安裝時精確控制 K3s 的行為和組件。

官方文件提供了詳細的配置指南：
*   [Configuration with Install Script](https://docs.k3s.io/installation/configuration#configuration-with-install-script)
*   [Environment Variables](https://docs.k3s.io/reference/env-variables)

其中，`INSTALL_K3S_EXEC` 環境變數允許您直接傳遞 K3s 執行檔的 CLI 參數，這對於細部調整 K3s Server 或 Agent 的行為至關重要：
*   [Server CLI Options](https://docs.k3s.io/cli/server)
*   [Agent CLI Options](https://docs.k3s.io/cli/agent)

## 常用安裝參數說明 (Common Args Explained)

### 指定 K3s 版本 (Specific Version)
在生產環境中，保持叢集組件的版本一致性是維護穩定性的關鍵。K3s 允許您在安裝時指定特定的版本，以避免自動更新可能帶來的兼容性問題。

1.  **查詢版本**: 首先，請查閱 [K3s Release Notes](https://docs.k3s.io/release-notes/v1.33.X) 以找到您希望安裝的 K3s 版本。
2.  **設定環境變數**: 在執行安裝腳本之前，設定 `INSTALL_K3S_VERSION` 環境變數即可。

```bash
export INSTALL_K3S_VERSION=v1.31.6+k3s1
curl -sfL https://get.k3s.io | sh -s -
```
這將確保您的 K3s 叢集安裝的是指定版本，有助於版本控制和環境的穩定性。

### 伺服器與代理節點 (Server/Agent)
K3s 叢集由一個或多個伺服器節點 (Server Nodes) 和可選的代理節點 (Agent Nodes) 組成。伺服器節點負責運行 Kubernetes 控制平面組件，而代理節點則運行工作負載。

*   **安裝伺服器節點**: 預設情況下，K3s 安裝腳本會安裝一個伺服器節點。
    ```bash
    # 在第一個伺服器節點 (e.g., node1) 上執行
    curl -sfL https://get.k3s.io | sh -
    ```

*   **獲取節點令牌 (Node Token)**: 伺服器節點啟動後，會生成一個用於代理節點加入叢集的令牌。
    ```bash
    # 在伺服器節點上執行
    sudo cat /var/lib/rancher/k3s/server/node-token
    ```
    請妥善保管此令牌，它將用於代理節點的認證。

*   **安裝代理節點**: 代理節點需要知道伺服器節點的地址和令牌才能加入叢集。
    ```bash
    # 在代理節點 (e.g., node2) 上執行
    export K3S_TOKEN=<從伺服器節點獲取的令牌>
    export K3S_URL=https://<伺服器節點 IP>:6443
    export INSTALL_K3S_EXEC="agent"
    curl -sfL https://get.k3s.io | sh -s -
    ```
    透過這種方式，您可以輕鬆地擴展您的 K3s 叢集。

### 服務負載平衡器 (Service Load Balancer)
Kubernetes 服務 (Service) 類型中的 `LoadBalancer` 允許外部流量訪問叢集內的應用程式。然而，Kubernetes 本身並不提供負載平衡器的實現，這通常需要雲服務提供商或第三方解決方案。

K3s 針對本地部署環境提供了一個內建的 [ServiceLB](https://docs.k3s.io/networking/networking-services?_highlight=traefik#service-load-balancer)。  
如果您計劃使用其他負載平衡器，例如 [MetalLB](https://metallb.universe.tf/)，可以在安裝時禁用 K3s 內建的 ServiceLB：
```bash
curl -sfL https://get.k3s.io | sh -s - --disable=servicelb
```
在許多情況下，為了簡化部署和提高效率，我個人更傾向於直接讓 Ingress Controller 使用主機網路 (Host Network) 模式來暴露服務，這可以避免額外的負載平衡器配置。

### Ingress Controller
Ingress Controller 負責管理對叢集內部服務的外部訪問。K3s 預設安裝了 [Traefik Ingress Controller](https://docs.k3s.io/networking/networking-services?_highlight=traefik#traefik-ingress-controller)。

如果您有偏好的 Ingress Controller (例如 Nginx Ingress Controller 或 HAProxy Ingress Controller)，可以在安裝 K3s 時禁用 Traefik：
```bash
curl -sfL https://get.k3s.io | sh -s - --disable=traefik
```
禁用後，您可以手動安裝和配置您選擇的 Ingress Controller。

### 高可用性嵌入式 etcd (High Availability Embedded etcd)
預設情況下，K3s 採用單一伺服器/多代理節點的架構，這意味著如果單一伺服器節點發生故障，整個叢集的控制平面將會中斷。為了提高叢集的彈性，K3s 提供了基於嵌入式 etcd 的高可用性解決方案。

透過在安裝時添加 `--cluster-init` 參數，您可以初始化一個高可用性叢集：
```bash
curl -sfL https://get.k3s.io | sh -s - --cluster-init
```
這將允許您部署多個 K3s 伺服器節點，它們將共同維護叢集的狀態，從而實現控制平面的高可用性。

## 建立高可用性 K3s 叢集 (K3s Cluster with HA)
結合上述知識，我們現在將建立一個具備高可用性的 K3s 叢集。為了確保 Kubernetes API Server 的持續可用性，我們將使用 Keepalived 來配置一個虛擬 IP (VIP)。當任何一個伺服器節點發生故障時，VIP 將會自動漂移到另一個健康的伺服器節點，確保控制平面始終可達。

**實驗環境設定**:
*   作業系統: Ubuntu 24.04
*   伺服器節點 IP: 192.168.56.101, 192.168.56.102, 192.168.56.103 (假設有三個伺服器節點)
*   虛擬 IP (VIP): 192.168.56.100 (用於 Kubernetes API Server)

### 1. 安裝 Keepalived
在所有三個伺服器節點上安裝 Keepalived：
```bash
sudo apt update && sudo apt install -y keepalived
```

### 2. 配置 Keepalived
在所有三個伺服器節點的 `/etc/keepalived/keepalived.conf` 中添加以下配置。請注意，`interface` 需要根據您的實際網路介面名稱進行修改。

```bash
sudo tee /etc/keepalived/keepalived.conf <<EOF
global_defs {
  enable_script_security
  script_user root
}
vrrp_script chk_kube-api-server {
    # check port 6443 is listening
    script "lsof -i :6443"
    interval 2          # 每 2 秒執行一次檢查
    fall 2              # 連續失敗 2 次後才觸發降級
    rise 1              # 連續成功 1 次後恢復正常優先級
    init_fail
}

vrrp_instance haproxy-vip {
    interface enp0s8 # 請根據您的實際網路介面名稱修改
    state BACKUP     # 初始狀態為 BACKUP，MASTER 將由優先級決定
    priority 100     # 優先級，數值越高優先級越高，MASTER 節點應設定更高優先級
    virtual_router_id 51 # VRRP 實例的唯一 ID，所有節點必須相同

    virtual_ipaddress {
        192.168.56.100/24 # 設定虛擬 IP 地址和子網路遮罩
    }
    track_script {
        chk_kube-api-server
    }
}
EOF
```
**設定說明**:
*   `global_defs`: 全局設定，`enable_script_security` 和 `script_user root` 確保腳本可以以 root 權限執行。
*   `vrrp_instance haproxy-vip`: 定義一個 VRRP 實例。
    *   `interface`: 監聽 VRRP 廣播的網路介面。
    *   `state`: 節點的初始狀態。在多個節點中，優先級最高的節點將成為 `MASTER`。
    *   `priority`: 節點的優先級。
    *   `virtual_router_id`: VRRP 實例的唯一標識符，所有參與 HA 的節點必須使用相同的 ID。
    *   `virtual_ipaddress`: 虛擬 IP 地址，這是外部流量將訪問的地址。

### 3. 重啟 Keepalived 並驗證
在所有伺服器節點上重啟 Keepalived 服務，並檢查虛擬 IP 是否已成功配置。
```bash
sudo systemctl restart keepalived

# 在任一伺服器節點上檢查網路介面，確認 VIP 已綁定
ubuntu@node1:~$ ip a show dev enp0s8
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:4b:9e:3d brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.101/24 brd 192.168.56.255 scope global enp0s8
       valid_lft forever preferred_lft forever
    inet 192.168.56.100/24 scope global secondary enp0s8 # 虛擬 IP 應該會顯示在這裡
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe4b:9e3d/64 scope link
       valid_lft forever preferred_lft forever
```
您應該會看到 `192.168.56.100/24` 作為輔助 IP 地址出現在網路介面上。

### 4. 安裝 K3s 伺服器節點 (HA 模式)
現在，我們將在三個伺服器節點上安裝 K3s，並配置它們以高可用性模式運行。

*   **第一個伺服器節點 (初始化叢集)**:
    在第一個伺服器節點上，使用 `--cluster-init` 參數來初始化 K3s 叢集。同時，我們禁用 Traefik 並設定 `kubeconfig` 檔案的權限，並將 VIP 加入 TLS SAN 列表，以便透過 VIP 訪問 API Server。
    ```bash
    # 在第一個伺服器節點上執行 (e.g., node1)
    export INSTALL_K3S_VERSION=v1.32.5+k3s1
    export INSTALL_K3S_EXEC="server --disable=traefik --write-kubeconfig-mode 644 --cluster-init --tls-san=192.168.56.100"
    curl -sfL https://get.k3s.io | sh -s -
    ```
    安裝完成後，獲取 `node-token`，這將用於其他伺服器節點加入叢集。
    ```bash
    sudo cat /var/lib/rancher/k3s/server/node-token
    ```

*   **其他伺服器節點 (加入叢集)**:
    在其他兩個伺服器節點上，使用 `--server` 參數指定第一個伺服器節點的 IP 地址（或 VIP），並使用 `--token` 參數提供 `node-token`。同樣，禁用 Traefik 並將 VIP 加入 TLS SAN 列表。
    ```bash
    # 在第二個和第三個伺服器節點上執行 (e.g., node2, node3)
    export INSTALL_K3S_VERSION=v1.32.5+k3s1
    export INSTALL_K3S_EXEC="server --disable=traefik --write-kubeconfig-mode 644 --server https://192.168.56.100:6443 --tls-san=192.168.56.100"
    export K3S_TOKEN=<從第一個伺服器節點獲取的令牌>
    curl -sfL https://get.k3s.io | sh -s -
    ```
    **注意**: `--server` 參數可以指向任何一個已啟動的 K3s 伺服器節點的 IP 地址，或者直接指向 Keepalived 的 VIP (192.168.56.100)。使用 VIP 可以確保即使第一個伺服器節點暫時不可用，其他節點也能成功加入。

### 5. 驗證高可用性叢集
所有伺服器節點安裝完成後，您可以透過以下命令驗證叢集狀態：
```bash
# 在任一伺服器節點上執行
kubectl get nodes
```
您應該會看到所有三個伺服器節點都處於 `Ready` 狀態。嘗試關閉其中一個伺服器節點，然後再次檢查 `kubectl get nodes`，您會發現叢集仍然正常運行，因為 Keepalived 已經將 VIP 漂移到另一個健康的伺服器節點。

## 總結 (Conclusion)
透過本文的介紹，您已經掌握了 K3s 的進階安裝參數，並成功建立了一個高可用性的 K3s 叢集。高可用性是生產環境中不可或缺的一環，它確保了叢集控制平面的穩定性和可靠性。

在下一篇文章中，我們將繼續探討 K3s 叢集建立後的一些基本配置，包括 Ingress Class、Storage Class 和 CNI (Container Network Interface) 等，這些都是構建完整 Kubernetes 環境的關鍵組件。


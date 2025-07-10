---
date: 2025-06-12T02:49:00
draft: false
tags:
- Vagrant
title: vagrant introduction
---
![](images/banner.jpeg)
<!--more-->

official site: https://developer.hashicorp.com/vagrant

Vagrant 是一個強大的開源工具，用於建立和管理輕量級、可攜式且可重複使用的開發環境。它透過自動化虛擬機的配置，讓開發者能夠在統一的環境中工作，無論團隊成員使用何種作業系統。

### 為什麼選擇 Vagrant？

在軟體開發中，環境一致性是提高效率和減少「在我的機器上可以跑」問題的關鍵。Vagrant 解決了以下痛點：

*   **環境差異：** 告別不同作業系統、函式庫版本或配置差異導致的問題。
*   **快速設定：** 新團隊成員或新專案啟動時，不再需要耗費數小時甚至數天來設定開發環境。
*   **可重複性：** 確保每次建立的環境都完全相同，有利於測試和部署。
*   **資源隔離：** 將開發環境與主機系統隔離，避免軟體衝突。
*   **版本控制：** Vagrantfile 可以像程式碼一樣被版本控制，方便追蹤環境變更。

對於 DevOps 和 SRE 專業人員來說，Vagrant 更是不可或缺的工具，它能幫助快速建立、測試和銷毀基礎設施環境，加速開發流程。

### 核心概念

在深入使用 Vagrant 之前，了解幾個核心概念至關重要：

*   **Box (基礎映像檔):** Vagrant 的基礎，類似於虛擬機的模板或快照。它是一個預先安裝好作業系統的虛擬機映像檔，Vagrant 會基於這個 Box 建立新的虛擬機。這比從 ISO 安裝作業系統快得多。
*   **Provider (虛擬化供應商):** 執行虛擬機的底層技術。Vagrant 預設支援 VirtualBox，但也支援 VMware、Hyper-V、Docker 等。雖然支援多種供應商，但為了避免相容性問題和簡化設定，建議初學者優先使用 VirtualBox。
*   **Vagrantfile (配置檔):** Vagrant 的核心，一個 Ruby 語言撰寫的配置檔。它定義了虛擬機的各種設定，包括使用的 Box、網路配置、共享資料夾、資源分配以及自動化腳本（Provisioners）。
*   **Provisioner (自動化配置工具):** 用於在虛擬機啟動後自動安裝軟體、配置系統或執行腳本。Vagrant 支援 Shell Script、Ansible、Chef、Puppet 等多種 Provisioner，確保開發環境的自動化配置。

## 快速入門

以下是使用 Vagrant 建立第一個虛擬機的基本步驟：

1.  **安裝 Vagrant:** 從 [Vagrant 官方網站](https://developer.hashicorp.com/vagrant/downloads) 下載並安裝適合您作業系統的版本。
2.  **安裝 VirtualBox:** Vagrant 預設使用 VirtualBox 作為虛擬化供應商。請從 [VirtualBox 官方網站](https://www.virtualbox.org) 下載並安裝。
3.  **建立 Vagrantfile:** 在您專案的根目錄下建立一個名為 `Vagrantfile` 的檔案。這是定義虛擬機配置的地方。

    ```ruby
    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    Vagrant.configure("2") do |config|
      # 指定使用的 Box，這裡使用 Ubuntu 20.04 LTS (Bionic Beaver)
      config.vm.box = "hashicorp/bionic64"

      # 配置虛擬機的網路，這裡設定一個私有網路，IP 為 192.168.56.101
      # 這樣可以從主機直接透過 SSH 連線到虛擬機
      config.vm.network "private_network", ip: "192.168.56.101"

      # 配置虛擬機的資源，例如 CPU 和記憶體
      config.vm.provider "virtualbox" do |v|
        v.memory = 2048 # 2GB 記憶體
        v.cpus = 2      # 2 個 CPU 核心
      end

      # 使用 Shell Provisioner 在虛擬機啟動後執行命令
      # 這裡示範更新套件列表並安裝 Nginx
      config.vm.provision "shell", inline: <<-SHELL
        sudo apt-get update
        sudo apt-get install -y nginx
        echo "Hello from Vagrant!" | sudo tee /var/www/html/index.nginx-debian.html
      SHELL
    end
    ```

4.  **啟動虛擬機:** 在 `Vagrantfile` 所在的目錄執行 `vagrant up` 命令。Vagrant 會自動下載 Box（如果尚未下載）、建立虛擬機並執行 Provisioner。

    ```bash
    vagrant up
    ```

5.  **連接虛擬機:** 虛擬機啟動後，您可以使用 `vagrant ssh` 命令透過 SSH 連接到虛擬機。

    ```bash
    vagrant ssh
    ```

6.  **清理環境:** 當您不再需要虛擬機時，可以使用 `vagrant destroy -f` 命令銷毀虛擬機及其所有相關檔案。

    ```bash
    vagrant destroy -f
    ```

## 進階技巧

### 1. 建立自訂 Box

雖然 Vagrant Cloud 上有許多現成的 Box，但在實際開發中，您可能需要一個預先安裝好特定軟體（如 Python、Node.js、資料庫等）的自訂 Box。這可以大幅縮短每次 `vagrant up` 的時間。

**步驟概覽：**

1.  在 VirtualBox 中手動建立一個虛擬機，安裝作業系統和所有必要的軟體。
2.  清理虛擬機（例如，移除歷史記錄、壓縮磁碟）。
3.  使用 `vagrant package` 命令將虛擬機打包成一個 `.box` 檔案。

    ```bash
    vagrant package --base <VirtualBox VM Name> --output custom.box
    ```

4.  將自訂 Box 添加到 Vagrant。

    ```bash
    vagrant box add custom-box custom.box
    ```

5.  在 Vagrantfile 中使用您的自訂 Box。

    ```ruby
    config.vm.box = "custom-box"
    ```

詳細步驟請參考 [Vagrant 官方文件：建立基礎 Box](https://developer.hashicorp.com/vagrant/docs/providers/virtualbox/boxes)。

### 2. 網路配置

Vagrant 提供了多種網路配置選項，以滿足不同的需求：

*   **NAT (預設):** 虛擬機可以訪問外部網路，但外部網路無法直接訪問虛擬機。適合簡單的開發環境。
*   **Private Network (主機專用網路):** 建立一個僅限主機和虛擬機之間通訊的網路。常用於設定固定 IP，方便主機上的其他工具（如 IDE、資料庫客戶端）連接虛擬機。

    ```ruby
    config.vm.network "private_network", ip: "192.168.56.101"
    ```

*   **Public Network (橋接網路):** 讓虛擬機像獨立的實體機器一樣連接到您的區域網路，擁有自己的 IP 位址。適合需要從外部網路訪問虛擬機的場景。

    ```ruby
    config.vm.network "public_network"
    ```

*   **Port Forwarding (連接埠轉發):** 將主機上的特定連接埠轉發到虛擬機上的連接埠，允許從主機或外部網路訪問虛擬機上運行的服務。

    ```ruby
    config.vm.network "forwarded_port", guest: 80, host: 8080 # 將虛擬機的 80 埠轉發到主機的 8080 埠
    ```

### 3. 管理多個虛擬機 (Multi-Machine)

Vagrant 的真正價值在於能夠在一個 Vagrantfile 中定義和管理多個虛擬機，這對於模擬分散式系統、叢集或多層應用程式架構非常有用。

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

$num_vms = 3 # 定義要建立的虛擬機數量
$vm_cpus = 2 # 每個虛擬機的 CPU 核心數
$vm_memory = 2048 # 每個虛擬機的記憶體大小 (MB)

Vagrant.configure("2") do |config|
  # 設定所有虛擬機共用的 Box
  config.vm.box = "hashicorp/bionic64" # 或者使用您自訂的 "custom-box"

  # 設定 SSH 登入憑證 (如果 Box 需要)
  config.ssh.username = "vagrant" # 預設的 Vagrant Box 通常使用 'vagrant'
  config.ssh.password = "vagrant" # 預設的 Vagrant Box 通常使用 'vagrant'

  # 配置 VirtualBox 供應商的通用設定
  config.vm.provider "virtualbox" do |v|
    v.linked_clone = true # 啟用連結複製，節省磁碟空間和加速建立
    v.gui = false         # 不顯示 VirtualBox GUI
  end

  # 使用迴圈建立多個虛擬機
  (1..$num_vms).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "node#{i}.example.com" # 設定虛擬機的主機名稱
      node.vm.network "private_network", ip: "192.168.56.#{100 + i}" # 設定私有網路 IP

      # 為每個虛擬機配置資源
      node.vm.provider "virtualbox" do |v|
        v.cpus = $vm_cpus
        v.memory = $vm_memory
      end

      # 為每個虛擬機執行 Provisioner
      node.vm.provision "shell", inline: <<-SHELL
        echo "Setting up node#{i}..."
        # 在這裡添加每個節點特有的配置腳本
        # 例如：安裝 Docker, Kubernetes 元件等
      SHELL
    end
  end
end
```

### 4. 連結複製 (Linked Clones)

當您需要建立多個虛擬機時，使用連結複製（Linked Clones）可以顯著節省磁碟空間和加速虛擬機的建立過程。連結複製的虛擬機共享一個基礎映像檔，只儲存與基礎映像檔不同的部分。

在 `Vagrantfile` 中啟用連結複製非常簡單：

```ruby
config.vm.provider "virtualbox" do |v|
  v.linked_clone = true
end
```

## 總結

Vagrant 是一個強大的工具，能夠簡化開發環境的建立和管理，提高團隊協作效率。透過理解其核心概念並善用進階功能，您可以為任何專案建立穩定、可重複且高效的開發環境。

希望這篇文章能幫助您更好地理解和使用 Vagrant！
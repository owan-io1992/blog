---
title: 初嘗 virt-manager
tags: [kvm, linux]
---

![banner](banner.png)
<!-- truncate -->

## 前言

[virt-manager](https://virt-manager.org) 是 linux 上的圖形化 virtual machines 的管理界面  
一直以來對於我都是使用 [virtualbox](https://www.virtualbox.org) 作為我開發用的 virtual machines 平台  
我對於這東西的印象依舊停留在 10 幾年前  
基本上就是"難用" 就直接忘了他了  

直到在前幾天看到有人在討論 virt-manager  
我才想說要再來試試看  

畢竟今非夕比, 過去我多使用 windows 平台  
而現在我大多使用 linux 平台  
virt-manager 對我來說多了一些吸引力  

**pros**  

1. 它是以 KVM 為底, 算 type-1 Hypervisor  
有天生的效能優勢  
詳細可以參考 AWS 介紹 [第 1 類與第 2 類 Hypervisor 之間有何差異？](https://aws.amazon.com/tw/compare/the-difference-between-type-1-and-type-2-hypervisors/)  

2. 由於工作上開始要接觸 openstack 與 proxmox  
由於都使用 KVM 因此可以更無縫的接軌 開發與 production 環境  

**cons**
1. 依舊沒有 virtualbox 那麼直接好用  
2. 使用者偏少數, 因此很吃技術  
3. vagrant 支援度是個大問號  

---

以目前來說
原本會使用 virtualbox 的話  
轉換 virt-manager 使用上並不難  
不過由於我平時用到 vagrant 因此卡關了許久  
以下來想我的歷程  


## what is virt-manager ?
以 linux 上做虛擬化來說  
會用到這些東西 KVM, QEMU, Libvirt, virt-manager  

以下讓 AI 簡單介紹一下  

1. KVM (Kernel-based Virtual Machine)
內建在 Linux 核心（Kernel）裡的一個模組  
它的角色：它是最底層的加速器。它利用現代 CPU 的硬體虛擬化技術（例如 Intel VT-x 或 AMD-V），讓虛擬機的 CPU 和記憶體可以直接在實體硬體上全速運作，而不需要經過軟體翻譯。  
它的限制：KVM 只負責 CPU 和記憶體。它不知道什麼是硬碟、網路卡、螢幕或滑鼠。如果只有 KVM，你根本無法開機跑作業系統。

2. QEMU (Quick Emulator)
QEMU 是一個強大的「軟體模擬器」  
它的角色：它負責模擬出所有 KVM 不管的硬體設備，包含虛擬的主機板、硬碟（如 qcow2 格式）、網路卡、USB 接口和顯示卡  
黃金組合 (QEMU + KVM)：如果只用 QEMU，它連 CPU 都要用軟體模擬，速度會超級慢。因此，在實務上我們會將它們結合：CPU 和記憶體交給 KVM 全速執行，剩下的周邊硬體交給 QEMU 模擬。 這就是我們常聽到的 KVM/QEMU 架構  

3. Libvirt
直接使用指令去控制 QEMU 其實非常複雜（指令可能會長達好幾行，包含各種硬體參數）  
它的角色：Libvirt 是一個管理工具和 API 介面（主要透過一個叫 libvirtd 的背景服務）。它把複雜的 QEMU 指令包裝起來，讓你用標準化的設定檔（通常是 XML 格式）來定義和管理虛擬機  
優勢：它不僅管理 QEMU/KVM，還可以順便管理虛擬網路（Virtual Networks）、儲存池（Storage Pools）。現在幾乎所有高階的虛擬化平台（如 OpenStack、Proxmox VE 底層概念）都是透過 Libvirt 在發號施令  

4. virt-manager (Virtual Machine Manager)
就算有了 Libvirt，寫 XML 設定檔還是有點麻煩，對一般使用者不夠直覺  
它的角色：virt-manager 是一個具有圖形化介面（GUI）的桌面應用程式  
運作方式：你在介面上點擊「新增虛擬機」、「設定 4GB 記憶體」、「掛載 ISO 檔」，virt-manager 就會在背後把這些動作翻譯成 Libvirt 看得懂的 API 呼叫，Libvirt 再去命令 QEMU 和 KVM 實際把虛擬機開起來  


---

聽起來很可怕  有好多東西  
但實際上要使用只要安裝 virt-manager  
剩下的會根據 dependencies 自動安裝  

install [virt-manager](https://virt-manager.org)
```bash
sudo apt install virt-manager
```

至於如何使用  
由於跟 virtualbox 挺像  
就不再細說了  

## auto create VM  
接著要處理的問題在於如何自動建立開發用的 VM  

由於 vagrant-libvirt 感覺已經沒在維護了  
因此嘗試使用 terraform 來解決問題  
幸好社群中有 [dmacvicar/terraform-provider-libvirt](https://github.com/dmacvicar/terraform-provider-libvirt) 可以使用  
因此這次最大的難點是將 vagrant 轉換到 terraform  

由於網路上已經存在許多大神寫的 terraform module  
我就不獻醜了, ~~反正也是叫 AI 幫忙寫~~  

單純紀錄心得  
1. 複雜, 學習曲線之高讓我一度想放棄  
2. bug, 畢竟用的人實在太少, 冷門的東西就是很容易踩雷  
3. 成就感  
由於需要自動協助設定 VM + 快速布建  
因此接觸到 cloud image 跟 cloud-init  
算是挺實用的技能  

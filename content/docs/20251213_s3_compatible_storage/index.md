---
date: 2025-12-13T2:00:00  
draft: false
tags: ["s3"]
title: "compare s3 compatible open-source storage"
---

說到 s3 compatible storage  
大家都會想到 minIO  
不管是在正式環境還是測試環境 都幫助許多專案運作  
然而在 2025/10/03 minIO open-source repo 進入 maintenance mode  
https://github.com/minio/minio/commit/27742d469462e1561c776f88ca7a1f26816d69e2

也等同正式宣告 minIO 要轉向閉源了  
雖然在早前就有跡象  
但這次變更也意味著社群要正式開始尋找替代方案了  

> [!NOTE]
> cephFS 不在我的考慮範圍內, 幾個原因  
> - object storage 與 block storage 目標並不同, cephFS 當 object storage 太浪費了  
> - cephFS 複雜的部屬需求並不適合用在開發/ CICD 環境  

以下嘗試用 google notebookLM 幫忙快速分析替代方案  

## S3 相容物件儲存詳細比較 (MinIO, RustFS, SeaweedFS, Garage)

### I. 核心架構與資源效率

| 參數 | MinIO | RustFS | SeaweedFS | Garage |
| :--- | :--- | :--- | :--- | :--- |
| **主要語言** | Go | Rust | Go | Rust |
| **底層架構** | 對稱式分散式架構 (Distributed)。 | **單層對稱式架構** (類似 MinIO)，無元數據中心。 | Master-Volume Server 架構，優化小檔案 (Haystack 模型)。 | **自包含/無外部依賴**，內部實作共識機制。 |
| **資料保護** | **抹除碼 (EC)**，Reed-Solomon 碼。 | **抹除碼 (EC)**，Reed-Solomon 碼 (內聯於組譯碼)。 | 簡單複製 (Replication)。EC 可作為溫資料儲存的選項。 | 複製 (Replication)，支援彈性複製係數。 |
| **儲存效率** | 高 (EC 最佳化，遠優於複製)。 | 高 (EC 最佳化)。 | 低 (複製開銷大)。 | 低 (複製開銷大)。 |
| **一致性模型** | 寫後讀/列後讀強一致性 (依賴底層檔案系統)。 | 嚴格的寫後讀一致性。 | 簡單一致性；故障時 Volume Server 可能轉為唯讀。 | **強一致性** (透過內部共識機制達成)。 |
| **資源需求** | 中等到高 (4–32 GB RAM/節點)。 | 輕量化 (單一二進位檔約 < 100 MB)，高並發性。 | 低 (2–4 GB RAM/節點)。 | **極低** (1–2 GB RAM/節點)。 |

---

### II. 性能指標與專業化

| 參數 | MinIO | RustFS | SeaweedFS | Garage |
| :--- | :--- | :--- | :--- | :--- |
| **大物件吞吐量** (Read/Write) | **高** (讀取 2.8 GB/s，寫入 2.1 GB/s)。 | **極高** (聲稱讀取 323 GB/s，寫入 183 GB/s)。 | 良好 (讀取 2.3 GB/s，寫入 1.8 GB/s)。 | 中等 (讀取 1.6 GB/s，寫入 1.2 GB/s)。 |
| **小物件延遲** (Small Object Latency) | 3.8ms 平均延遲。 | 宣稱比 MinIO 快 2.3 倍 (針對 4KB 物件)。 | **最低** (2.1ms 平均延遲)。 | 4.2ms 平均延遲。 |
| **優化技術** | 針對 AI/ML 工作負載優化。利用 **SIMD** 指令集加速 S3 Select 等複雜查詢。 | 利用 **Rust 記憶體安全** 和組譯碼 **EC 優化**，針對資料湖工作負載設計。 | 採用 Haystack 模型，實現 **O(1) 磁碟讀取操作**，減少尋道時間。 | 優先考慮營運穩定性與 Geo-Distribution。 |

---

### III. S3 兼容性與進階功能

| S3 核心功能 | MinIO | RustFS | SeaweedFS | Garage |
| :--- | :--- | :--- | :--- | :--- |
| **S3 兼容性標準** | **最廣泛、最完整**，是 S3 兼容性的行業標準。 | **100% 兼容**，最廣泛測試和部署的 S3 替代方案之一。 | **基本操作** (PUT/GET)。功能有顯著缺陷。 | **核心兼容**，適用於 rclone、Cyberduck 等常見客戶端。 |
| **S3 Select** (資料湖查詢) | **支援**，性能優化。 | **支援**，對資料湖/分析至關重要。 | **不支援**。 | 不支援。 |
| **物件版本控制** (Versioning) | **支援** (與 Object Lock 結合)。 | **支援** (用於 Active-Active 複製)。 | **不支援** (測試中造成 510 個錯誤)。 | 不支援。 |
| **物件鎖定** (WORM/Immutability) | **支援** (GOVERNANCE/COMPLIANCE 模式)，符合 SEC17a-4(f) 等法規。 | **支援** (GOVERNANCE/COMPLIANCE 模式)，提供法律保留功能。 | 不支援。 | 不支援。 |
| **IAM 策略兼容性** | 支援 AWS IAM 策略語法和行為。 | 支援 AWS IAM 策略語法和行為。 | 支援有限。 | 支援有限。 |
| **Kubernetes 整合** | **MinIO Operator** 處理部署與管理。 | 支援 Helm Charts。 | 支援 CSI Driver 和 Operator。 | 支援 Kubernetes/Nomad 整合。 |

---

### IV. 授權與社群狀態 (商業考量)

| 參數 | MinIO | RustFS | SeaweedFS | Garage |
| :--- | :--- | :--- | :--- | :--- |
| **開源授權** | **AGPLv3** (強拷貝左派，企業商業風險高)。 | **Apache 2.0** (商業友好，無 IP/合規風險)。 | **Apache 2.0** (商業友好)。 | **AGPL-3.0** (強拷貝左派，企業商業風險高)。 |
| **社群/發布狀態** | **目前處於「維護模式」** (Maintenance Mode)，不接受新功能或 PR。社群版僅原始碼發布，管理 UI 被移除。 | 活躍，但因要求貢獻者轉讓版權 (CLA) 和激進的市場宣傳，社群存在疑慮。 | 活躍，持續更新，提供單一二進位檔下載。 | 活躍，被社群譽為「磐石般堅固」 (rock solid)，持續獲得公共資金支持。 |
| **定位與建議** | 適用於需要極高性能、完整 S3 兼容性的大型企業資料湖/AI/ML 工作負載，但須處理 AGPLv3 帶來的法律或商業風險。 | 適用於需要最高吞吐量、高儲存效率和 **全面 S3 功能** 的雲原生和資料湖環境，並尋求 MinIO 的 Apache 2.0 替代品。 | 適用於需要 **極低延遲** 存取大量小檔案的 CDN、圖片伺服器或日誌儲存。 | 適用於 **資源受限環境**、家庭實驗室 (homelab) 或邊緣部署，優先考慮部署簡單性與運營穩定性。 |

---

另外補充
https://www.repoflow.io/blog/benchmarking-self-hosted-s3-compatible-storage-a-practical-performance-comparison  

rustFS 目前來說還是 alpha 階段  不建議此時採用  
且他是具有中國色彩 就算 stable 後 個人也是不建議採就用  

SeaweedFS 嚴格上來說與 cephFS 有點像, 只是額外提供 S3 compatible   
這樣看來 garage 算是替代 minIO 較好的選擇  

因此 接下我來會著手替換手上的 minIO to garage  
之後再寫篇文章介紹 garage  
---
title: "企業級日誌架構設計對比：rsyslog vs Fluent Bit 於混合基礎設施的四種拓撲"
description: "針對混合環境（Linux Server、OpenStack、Docker、K8s、Ceph）匯流至 Elasticsearch 與 Rsyslog Server 的四種日誌架構深度比較與選型建議。"
tags: [logging, architecture, devops, k8s, openstack, ceph, fluent-bit, rsyslog]
---

<!-- truncate -->

在企業級私有雲與混合基礎設施中，日誌來源往往跨越多個世代與不同運算層：
* **作業系統層**：Linux 實體伺服器 / 虛擬機（OS Auth, Syslog, Audit）。
* **雲端與儲存基礎設施**：**OpenStack**（Nova, Neutron, Keystone 等日誌）與 **Ceph**（OSD, MON, MGR, RGW 日誌）。
* **容器平台層**：**Docker Engine** 與 **Kubernetes (K8s)**（Pod 容器標準輸出、Containerd、CRI 日誌、K8s Event）。

而收集的目的地通常有雙重需求：
1. **即時檢索與可觀測性分析平台**：**Elasticsearch**（供 Kibana 查詢、排查告警、APM）。
2. **法規遵循與集中封存平台**：**Rsyslog Server**（合規稽核、只讀歸檔、長週期冷儲存、SIEM 轉發）。

本文將針對這類複雜異質架構，深度剖析 **4 種主流日誌收集架構模式（Topologies）**，對比各自的優缺點、背壓控制、維運成本與適用場景。

---

## 一、情境與挑戰分析

混合環境下的日誌採集面臨以下四大挑戰：

```mermaid
flowchart TD
    subgraph 來源端[異質來源端 (Sources)]
        L[Linux OS Logs]
        O[OpenStack Services]
        C[Ceph Cluster]
        D[Docker Containers]
        K[K8s Pods / CRI]
    end

    subgraph 採集與傳輸層[架構選型核心 (Edge Agent / Aggregator)]
        direction TB
        M1[模式 1: 全 rsyslog 直送]
        M2[模式 2: rsyslog + 中繼 Fluent Bit]
        M3[模式 3: 全 Fluent Bit 直送]
        M4[模式 4: Fluent Bit + 中繼 Fluent Bit]
    end

    subgraph 目的地[目標後端 (Destinations)]
        ES[(Elasticsearch<br>檢索/告警/Kibana)]
        RS[(Rsyslog Server<br>合規稽核/長存)]
    end

    來源端 --> 採集與傳輸層 --> 目的地
```

1. **資料格式分歧**：
   - OpenStack / Ceph 多為文字檔案或自帶 Syslog 格式。
   - Docker / K8s 多為 JSON / CRI 串流日誌，需要動態添加 Pod Name、Namespace、Container ID、Label 等 Metadata。
2. **雙目標後端的協定差異**：
   - Elasticsearch 需要 **HTTP / REST (JSON Bulk)** 協定與高吞吐批次寫入。
   - Rsyslog Server 則需要 **RFC3164 / RFC5424 (UDP/TCP/RELP)** 協定。
3. **節點資源與網路背壓**：
   - 伺服器故障或大量報錯時，若缺乏本地 Buffer，易導致節點記憶體暴漲或日誌遺失。

---

## 二、四種架構模式深度對比

---

### 模式 1：來源端 rsyslog 直送（Direct Dual Shipping）

> **架構流程**：各 Node 使用內建 `rsyslog`，同時透過 TCP/RELP 送至遠端 Rsyslog Server，並透過 `omelasticsearch` 模組直接寫入 Elasticsearch。

```text
[Linux / OpenStack / Ceph / Docker / K8s Node]
   │ (內建 rsyslog 讀取 /var/log 與 journald)
   ├───► TCP / RELP ─────────────► [ Rsyslog Server ]
   └───► HTTP (omelasticsearch) ──► [ Elasticsearch ]
```

#### 優點：
1. **零額外部署 Agent**：所有 Linux 發行版皆預載 rsyslog，無需安裝額外第三方 Agent，基礎維運成本極低。
2. **架構極簡、少一層跳躍（Hop）**：資料直達目的地，無中間層維護成本與網路中繼延遲。
3. **系統層級效能優異**：rsyslog 基於 C 語言打造，消耗 CPU 與記憶體極低。

#### 缺點：
1. **K8s 與容器支援度極差**：
   - rsyslog 不具備自動對接 Kubernetes API 裝飾 Metadata（Pod, Namespace, Container Name）的能力。
   - 無法有效監聽動態輪轉的 Docker/Containerd 日誌。
2. **ES 模組功能陽春**：
   - `omelasticsearch` 缺乏靈活的 JSON 清洗、條件路由、型別轉換與多重 Index 模板動態匹配能力。
3. **連線數爆發（Connection Explosion）**：
   - 每台 Node 都要直連 Elasticsearch，叢集節點達到數百台時，ES Ingest 節點會被巨量 HTTP 連線塞滿。
4. **無法保證送達（極易掉 Log）**：
   - **協定限制**：UDP 模式完全無 ACK；純 TCP 模式下，若遇到遠端伺服器短暫重開或網路斷線，已送入 OS Send Buffer 的日誌會直接蒸發。
   - **記憶體佇列溢位丟包**：rsyslog 預設 Action Queue 跑在純記憶體中，一旦目標 ES 響應慢或塞車，佇列塞滿後的預設策略就是直接丟棄新日誌。
   - **`omelasticsearch` 背壓脆弱**：面對 ES 回傳的 `429 Too Many Requests` 或寫入逾時，重試邏輯難以應付高並發突發流量，極易阻塞並引發大量丟日誌。
5. **多來源混雜時「完全無法分清來源」**：
   - 傳統 rsyslog 僅能識別主機名稱（`$HOSTNAME`）與程序名（`$programname`）。
   - 面對 **Kubernetes 與 Docker**，所有容器輸出全被視為 `containerd` 或一串隨機 Hash，完全遺失 Pod、Namespace 與 Label 等上下文。
   - 面對 **Ceph 與 OpenStack** 容器化或多 Daemon（如單機 24 顆 OSD），無法自動提取動態 ID，進到 Elasticsearch 後全混雜為非結構化文字，無法精準篩選排查。

---

### 模式 2：來源端 rsyslog + 集中式 Fluent Bit 中繼（Centralized Aggregator）

> **架構流程**：各 Node 本地 rsyslog 只負責將資料以標準 Syslog 協定拋給中繼的 **Fluent Bit Aggregator**；由 Fluent Bit 統一完成解析、正規化，再分流至 Elasticsearch 與 Rsyslog Server。

```text
[Linux / OpenStack / Ceph Node]
   │ (rsyslog syslog forward)
   ▼
[ 集中式 Fluent Bit Aggregator (Syslog Input) ]
   ├───► Filter (Parser, JSON, Add Fields)
   ├───► Output: elasticsearch ───► [ Elasticsearch ]
   └───► Output: syslog / tcp ────► [ Rsyslog Server ]
```

#### 優點：
1. **邊緣端維持零部署負擔**：實體機與儲存節點保持原汁原味，只需修改 `/etc/rsyslog.d/*.conf` 將日誌轉發至中繼層。
2. **保護後端儲存**：由 Fluent Bit 負責收攏連線並進行 Batch Bulk 寫入，Elasticsearch 不會暴露於巨量客戶端連線下。
3. **清洗與路由集中化**：所有的解析規則、欄位遮蔽（如遮蔽密碼）、格式轉換皆在中繼層統一維護。

#### 缺點：
1. **中繼層負載與單點風險**：
   - 中繼 Fluent Bit 必須承載全網流量，需配置 HAProxy / Keepalived 做負載平衡，或部署多個副本。
2. **K8s 容器日誌仍是痛點**：
   - 雖然解決了 OpenStack、Ceph 與 Linux OS 的問題，但 K8s Node 仍需額外方案才能解析出完整容器標籤。
3. **失去本地日誌屬性**：
   - Syslog 協定傳輸時若未妥善封裝原始訊息，容易遺失原始檔案名稱、偏移量（offset）或行號。

---

### 模式 3：來源端 Fluent Bit 直送（Edge-to-Storage Direct）

> **架構流程**：各 Node（無論是實體機、Ceph 節點還是 K8s 節點）皆安裝 **Fluent Bit Agent**，本地讀取日誌後，同時配置多個 Output 直送 Elasticsearch 與 Rsyslog Server。

```text
[Linux / OpenStack / Ceph / K8s Node]
   │ (Fluent Bit: in_tail, in_systemd, in_kubernetes)
   ├───► Output: elasticsearch ──► [ Elasticsearch ]
   └───► Output: syslog / tcp ────► [ Rsyslog Server ]
```

#### 優點：
1. **雲原生與容器最佳實踐**：
   - 內建 `kubernetes` filter，自動掛鉤 K8s API，Pod Name / Label 隨日誌完整附帶。
2. **強大的本地邊緣清洗與背壓（Backpressure）**：
   - 支援本地 Memory Buffer + Disk Buffer（Storage.type: filesystem）。
   - 當 Elasticsearch 發生維護或網路抖動時，節點本地暫存，不會拖垮記憶體或造成日誌遺失。
3. **無中繼層轉發延遲**：日誌由邊緣直接送到終點，故障排查路徑最短。

#### 缺點：
1. **邊緣管理負擔增加**：
   - 每台實體 Linux、Ceph、OpenStack 伺服器都需要安裝、維護與升級 Fluent Bit Binary 及配置檔案。
2. **連線與權限管理繁瑣**：
   - 每個節點都需要有通往 Elasticsearch 與 Rsyslog Server 的網路路由、防火牆白名單與認證 Token / 憑證。

---

### 模式 4：來源端 Fluent Bit + 集中式 Fluent Bit 中繼（兩層式架構 / Two-tier Pipeline）

> **架構流程**：邊緣節點使用輕量級 Fluent Bit（或 DaemonSet）採集本機日誌，統一使用極輕量且高效的 `forward` 協定送到中繼的 **Fluent Bit Aggregator**；由中繼層執行高負載的過濾、正規化，再批量寫入 Elasticsearch 與 Rsyslog Server。

```text
[Edge Nodes: Linux / OpenStack / Ceph / K8s]
   │ (Edge Fluent Bit: in_tail / in_systemd / in_k8s)
   │ 僅做輕量 Tagging 與標記
   ▼ (Fluentd Forward 協定 / 壓縮傳輸)
[ Fluent Bit Aggregator 集群 (Load Balanced) ]
   │ (重度清洗 / 路由 / 認證管理 / 集中 Disk Buffer)
   ├───► Output: elasticsearch (Bulk HTTP) ──► [ Elasticsearch ]
   └───► Output: syslog (RFC5424 TCP) ──────► [ Rsyslog Server ]
```

#### 優點：
1. **責任分離（Separation of Concerns）**：
   - **邊緣端**：極致輕量（只做讀檔、Tagging 與壓縮轉發，CPU < 2%，Mem < 30MB）。
   - **中繼層**：扛下高運算消耗的正則解析、跨表查詢、欄位脫敏與 Bulk 寫入。
2. **極致安全與網絡收攏**：
   - 邊緣節點不需要直接連外或存取 Elasticsearch 叢集，只需開放單一內部連接埠至 Aggregator。
   - 後端憑證與密碼只存放在中繼層，降低外洩風險。
3. **優異的集中背壓與容災**：
   - 中繼層可掛載大容量 SSD 啟用持久化 Disk Buffer，即使 Elasticsearch 當機數小時，整個企業的日誌依然安全無虞。

#### 缺點：
1. **架構複雜度最高**：
   - 需維護 Edge Agent 與 Aggregator 集群兩套不同的配置檔案與生命週期。
2. **額外的網路與資源跳躍開銷**：
   - 多一層節點跳躍（額外約數毫秒的延遲），需要規劃 Aggregator 的伺服器運算資源。

---

## 三、四大架構綜合評比矩陣

| 評估維度 | 模式 1：全 rsyslog 直送 | 模式 2：rsyslog + 中繼 Fluent Bit | 模式 3：全 Fluent Bit 直送 | 模式 4：兩層式 Fluent Bit (推薦) |
| :--- | :--- | :--- | :--- | :--- |
| **K8s / 容器 Metadata 支援** | 🔴 極差（無法原生關聯） | 🔴 差（難以自動獲取 Pod 標籤） | 🟢 優秀（內建 Filter 原生支援） | 🟢 極佳（Edge 端打標，後續完整保留） |
| **OpenStack / Ceph 支援** | 🟢 原生支援（內建 syslog） | 🟢 原生支援（轉發簡單） | 🟢 良好（tail 檔案或 systemd） | 🟢 良好（統一轉發） |
| **Elasticsearch 連線壓力** | 🔴 巨大（所有節點直連 ES） | 🟢 極小（由 Aggregator 聚合） | 🔴 較大（所有節點直連 ES） | 🟢 極小（由 Aggregator 聚合） |
| **解析與清洗彈性** | 🔴 陽春（Regex/Dissect 繁瑣）| 🟡 良好（集中處理） | 🟢 優秀（分佈在邊緣節點） | 🟢 極高（邊緣粗洗 + 中繼深洗） |
| **背壓（Backpressure）與容災** | 🟡 一般（依賴 Action Queue）| 🟡 中等（受限於邊緣 syslog buffer）| 🟢 優秀（本地 Disk Buffer） | 🟢 極佳（雙層 Buffer 保護） |
| **邊緣節點維運成本** | 🟢 最低（無額外軟體） | 🟢 最低（只需改設定） | 🟡 中等（需維護全節點 Agent） | 🟡 中等（Edge 配置保持最簡） |
| **整體架構複雜度** | 🟢 最簡單 | 🟡 中等 | 🟡 中等 | 🔴 最高（需維護兩層） |

---

## 四、深入剖析：來源端 rsyslog 直送為什麼無法保證不掉 Log？

在實務架構評審中，許多團隊會問：*「rsyslog 本地讀取、遠端拋送這麼多年，為什麼在現代架構下會被認為無法保證不掉 Log？」*

答案在於**傳統 Syslog 設計定位與現代高吞吐/分散式儲存的根本脫節**：

### 1. 傳統 Syslog 傳輸缺乏「應用層確認（Application-level ACK）」
* **UDP 模式 (`@host`)**：屬於 Best-effort 盡力而為，完全無確認機制，網路壅塞或緩衝區滿溢即丟棄。
* **TCP 模式 (`@@host`)**：雖然底層 TCP 保證傳輸層可靠，但 **Syslog 協定本身沒有應用級確認**。當日誌進入作業系統的 TCP Socket 發送隊列後，rsyslog 即視為成功；如果目標端在落盤前伺服器當機或斷線，已送出的日誌將無聲無息地遺失。

### 2. 預設純記憶體佇列（In-Memory Queue）與溢位丟棄
* rsyslog 預設的 Action Queue 是跑在記憶體中的。
* 當後端 Elasticsearch 發生 GC 停頓、Index 限流（429 Too Many Requests）或網路短暫抖動時，節點本地的佇列會在幾秒鐘內被填滿。
* 一旦佇列達到上限，rsyslog 預設策略即為 **`Discard`（丟棄新進來的 Log）**。雖然可透過手動配置 `Disk-Assisted Queue`（磁碟輔助佇列）緩解，但在全網數十到數百台節點上逐一維護磁碟佇列的設定難度極高。

### 3. `omelasticsearch` 模組的背壓（Backpressure）脆弱性
* Elasticsearch 是高並發分散式搜尋引擎，面對突發流量極度依賴 **批次寫入（Bulk API）** 與 **指數退避重試（Exponential Backoff）**。
* rsyslog 的 `omelasticsearch` 模組本質上偏向小批次發送，對 HTTP 429、503 等狀態碼的處理機制遠不如專業的現代收集器（如 Fluent Bit、Logstash、Vector）。在高壓測試下（如 Ceph 正在大規模 Recovery 產生海量日誌時），`omelasticsearch` 很容易出現 Thread 阻塞或重試超時丟棄。

### 4. 與 Fluent Bit 的可靠性機制對比

| 保證機制維度 | 來源端 rsyslog 直送 | 來源端 Fluent Bit 直送 / 兩層式 |
| :--- | :--- | :--- |
| **檔案偏移量追蹤** | 依賴 `imfile` state file，日誌輪轉（logrotate）時較易遺失或重複 | 內建 SQLite 游標庫 (`db: tail.db`)，依據 Inode + Offset 精確追蹤 |
| **本地磁碟暫存 (Buffer)** | 預設純記憶體；配置磁碟隊列繁瑣且容易出錯 | 原生一行 `storage.type filesystem` 即可啟用磁碟持久化緩衝 |
| **HTTP 429 / 故障重試** | 重試機制陽春，容易阻塞或超時丟棄 | 內建完整指數退避重試（`Retry_Limit`），網路斷線自動重連補發 |
| **整體送達保證等級** | 🔴 **At-most-once (最多送達一次，極易丟失)** | 🟢 **At-least-once (至少送達一次，保證不丟失)** |

---

## 五、深入剖析：面對多來源（K8s / Docker / OpenStack / Ceph），rsyslog 能分清來源嗎？

在評估日誌架構時，除了「能否送到」，另一個決定架構生死的關鍵是：**「送進 Elasticsearch 後，維運人員到底能不能按來源精準查詢？」**

結論是：**rsyslog 在傳統固定檔案下勉強能區分，但在現代混合動態環境中幾乎「完全分不清來源」！**

### 1. rsyslog 的來源識別機制與局限
傳統 rsyslog 僅原生提供兩個識別維度：
* **`$HOSTNAME`**：來源伺服器主機名。
* **`$programname`（或 `Tag`）**：程序名稱（如 `sshd`、`kernel`）。

若要讀取其他日誌，必須手動透過 `imfile` 插件針對每一個日誌檔案逐一寫死 `Tag`：
```ini
# Ceph OSD 需手動逐一定義
input(type="imfile"
      File="/var/log/ceph/ceph-osd.0.log"
      Tag="ceph-osd"
      Facility="local0")
```

### 2. 為什麼在混合來源下 rsyslog 會徹底失效？

1. **Kubernetes 與 Docker 容器日誌（完全失去上下文）**：
   - 容器日誌的路徑是動態輪轉的亂數命名（如 `/var/log/pods/prod_payment-7f9b8.../app/0.log`）。
   - rsyslog 不具備呼叫 Kubernetes API 的能力，拋送出去時 `$programname` 往往全都是 `containerd`、`dockerd` 或一串隨機 Hash。
   - **後果**：進到 Elasticsearch 之後，幾百個微服務的 Log 全混在一起，無法按 `k8s.namespace` 或 `k8s.pod_name` 篩選排障。
2. **Ceph 多 Daemon 與多 OSD 混雜**：
   - 一台儲存節點常同時掛載 24~36 顆 OSD。
   - rsyslog 的萬用字元（wildcard）支援無法動態將檔名中的 OSD 序號（`ceph-osd.12.log`）動態提取為獨立欄位，排查時難以即時定位是哪一顆硬碟故障。
3. **OpenStack 容器化服務混淆**：
   - 若 OpenStack 是以容器化方式部署（如 Kolla-Ansible / OpenStack-Helm），日誌全跑在容器標準輸出內，rsyslog 看到的只有容器執行緒，分不清是 Nova、Neutron 還是 Cinder。

---

### 3. Fluent Bit 是如何完美解決來源辨識的？

Fluent Bit 採用了完全不同的 **「動態標籤路由 (Tag-driven Routing) + Metadata 裝飾 (Metadata Enrichment)」** 架構：

```text
[原始來源] ──► 依路徑正規化動態打標 (Tag) ──► Filter: kubernetes (注入 K8s API 元數據)
                                         └──► Filter: rewrite_tag / parser (提取 Ceph OSD ID)
```

寫入 Elasticsearch 時會自動展開為完整的結構化 JSON 物件：
```json
{
  "log": "2026-09-28 ERROR Connection refused",
  "host": "k8s-worker-node-03",
  "kubernetes": {
    "namespace_name": "payment",
    "pod_name": "checkout-service-7f9b867bc-x9z2p",
    "container_name": "api",
    "labels": { "app": "checkout", "env": "production" }
  },
  "service": {
    "type": "ceph",
    "daemon": "osd",
    "osd_id": 12
  }
}
```

### 4. 來源識別能力全方位對照表

| 來源識別能力 | rsyslog 直送模式 | Fluent Bit 模式 |
| :--- | :--- | :--- |
| **實體主機名 (Hostname)** | 🟢 支援 (`%HOSTNAME%`) | 🟢 支援 (`${HOSTNAME}` 標記) |
| **靜態服務區分** | 🟡 勉強支援（需手工為每個檔案寫死 `imfile Tag`） | 🟢 優異（Regex 動態匹配） |
| **Ceph 多 OSD 自動提取** | 🔴 困難（萬用字元會遺失 OSD ID 欄位） | 🟢 輕鬆（Regex 提取成為 JSON key） |
| **OpenStack 容器化服務** | 🔴 極難（全被視為 containerd 日誌） | 🟢 良好（可解析容器名稱打標） |
| **K8s Pod / Namespace 標籤** | 🔴 **完全無法分清** | 🟢 **原生完美支援（附帶完整 Labels）** |
| **在 Elasticsearch 中的呈現** | 偏向一段未結構化的文字字串 | **完整的 JSON 樹狀結構欄位，方便 Kibana 聚合** |

---

## 六、選型建議指南

針對包含 **Linux Server、OpenStack、Docker、K8s 與 Ceph** 的混合環境，建議依團隊維運能力與規模依序評估：

### 🎯 方案 A：最具擴展性與彈性的首選 ——「模式 4：兩層式 Fluent Bit」
* **適合情境**：
  - K8s 節點數超過 50 節點，或全環境日誌量超過每日 500GB。
  - 安全規範嚴格，運算節點不可直接連線日誌儲存核心網路。
  - 需要在日誌入庫前進行深度的 PII 脫敏或動態路由。
* **部署建議**：K8s 內以 DaemonSet 部署 Edge Fluent Bit；OpenStack 與 Ceph 節點統一安裝輕量 Fluent Bit Client；中繼層以 2~3 台虛擬機搭配負載平衡器提供高可用。

### 🎯 方案 B：中小型環境或希望架構精簡 ——「模式 3：全 Fluent Bit 直送」
* **適合情境**：
  - 伺服器總數在 30 ~ 50 台以內，且網路拓撲平整（邊緣節點可直接連線 Elasticsearch 與 Rsyslog）。
  - 希望快速上線，不想額外管理一組 Aggregator 負載平衡器與中繼叢集。
* **部署建議**：所有節點使用 Ansible 統一部署 Fluent Bit，針對不同角色（K8s, Ceph, OpenStack）分發對應的 `fluent-bit.yaml`。

### 🎯 方案 C：維運保守、傳統實體伺服器佔比高 ——「模式 2 改良型 (混合收集)」
* 若 OpenStack 與 Ceph 叢集有嚴格限制「不准在節點安裝第三方非原生 Agent」：
  - **OpenStack / Ceph / Linux**：維持原生 `rsyslog`，統一拋送至中繼 Fluent Bit Aggregator。
  - **Kubernetes 叢集**：內部獨立跑 Fluent Bit DaemonSet，直連或透過 Forward 協定送至 Aggregator。
  - 這是在舊有基礎設施與現代雲原生容器之間取得平衡的最佳妥協方案。

---
title: "Log Agent Benchmark 實戰：Fluent Bit vs Vector vs Filebeat 60秒壓測評評"
description: "使用 Docker Compose 與 flog 進行 Fluent Bit、Vector 與 Filebeat 的極限效能壓測，詳細記錄 CPU、記憶體 (RSS)、BLOCK I/O 零磁碟讀取與千萬級日誌吞吐量分析。"
tags: [logging, devops, benchmark, docker, performance]
---

<!-- truncate -->

在評估日誌架構（Log Pipeline）時，除了功能支援與生態系，最直接影響維運成本與系統穩定度的就是 **效能吞吐量** 與 **資源佔用（CPU / 記憶體 / 磁碟 I/O）**。

本文建立了一套可重現的本機 Docker Compose 基準壓測環境，透過高頻日誌產生器 `mingrammer/flog` 進行持續 60 秒的百萬級高負載測試，橫向對比三大主流日誌 Agent：
* **Fluent Bit (C)**：v5.1.2
* **Vector (Rust)**：v0.58.0
* **Filebeat (Go)**：v8.19.22

架構與生態比較請參考系列文章：[Log Agent 深度對比：Fluent Bit vs Vector vs Elastic Agent](../2026-09-28_log-agent-compare/index.md)。

---

## 測試架構設計

```text
       [ benchmark-log-tester ]
 (mingrammer/flog 高頻輸出 JSON 日誌)
                  │
                  ▼ 寫入
   [ 共享 Volume: /var/log/app/app.log ]
                  │
                  ├───► [ Fluent Bit (C) ]      --> JSON Tail 解析 --> Output Null
                  ├───► [ Vector (Rust) ]       --> VRL JSON 解析  --> Sink Blackhole
                  └───► [ Elastic Filebeat (Go)]--> NDJSON 解析   --> Output Null (/dev/null)
```

1. **公平性原則**：
   - 三者同時掛載同一個共享磁區讀取 `/var/log/app/app.log`。
   - 皆進行標準 JSON 日誌解析與反序列化。
   - 輸出端皆丟棄至 `null` 或 `blackhole`，排除外部網路頻寬與後端儲存（Elasticsearch/Loki/Kafka）的 I/O 瓶頸，純粹測試 **收集引擎與解析管線** 的極限開銷。
2. **監控維度**：
   - 即時資源消耗：CPU%、記憶體（RSS）、BLOCK I/O（磁碟讀寫量）、網路 I/O。
   - 吞吐統計：透過各 Agent 官方指標端點（Fluent Bit `:2020` Prometheus、Vector `:9090` Prometheus、Filebeat `:5066` HTTP Stats）統計 60 秒內的實際讀取與完成筆數。

---

## 測試環境專案結構與源碼下載

本測試所有設定檔與自動化腳本已完整開源，您可以直接 clone 倉庫取得檔案：

* **GitHub 專案目錄**：[`owan-io1992/blog (2026-09-28_log-agent-benchmark)`](https://github.com/owan-io1992/blog/tree/main/my-website/blog/2026-09-28_log-agent-benchmark)

```text
2026-09-28_log-agent-benchmark/
├── docker-compose.yml           # 壓測容器編排 (flog, fluent-bit, vector, filebeat)
├── run-benchmark.sh             # 60 秒即時資源快照與指標彙整腳本
└── configs/
    ├── fluent-bit/
    │   └── fluent-bit.yaml      # Fluent Bit 高吞吐多執行緒與 Page Cache 調優配置
    ├── vector/
    │   └── vector.yaml          # Vector VRL 解析與 Blackhole Sink 配置
    └── elastic-agent/
        └── filebeat.yml         # Filebeat Filestream 解析配置
```

---

## 快速重現測試步驟

```bash
# 賦予執行權限並執行自動化壓測腳本
chmod +x ./run-benchmark.sh
./run-benchmark.sh
```

如需手動觀察即時狀態：
```bash
# 啟動所有服務
docker compose up -d

# 觀察即時資源消耗
docker stats benchmark-fluent-bit benchmark-vector benchmark-filebeat

# 測試結束清理環境
docker compose down -v
```

---

## 服務埠號與指標端點

- **Fluent Bit**: `http://localhost:2020/api/v1/metrics/prometheus`
- **Vector**: `http://localhost:8686/health` / 指標: `http://localhost:9090/metrics`
- **Filebeat**: `http://localhost:5066/stats`

---

## 60 秒壓測實測結果

```text
==========================================================
      Log Agent Benchmark: Fluent Bit vs Vector vs Beats
==========================================================
[1/4] 清理舊環境與 Volume...
[2/4] 啟動測試環境 (log-tester, fluent-bit, vector, filebeat)...
[+] up 6/6
 ✔ Network benchmark_default      Created                                   0.0s
 ✔ Volume benchmark_shared-logs   Created                                   0.0s
 ✔ Container benchmark-log-tester Started                                   0.3s
 ✔ Container benchmark-fluent-bit Started                                   0.3s
 ✔ Container benchmark-vector     Started                                   0.5s
 ✔ Container benchmark-filebeat   Started                                   0.6s
[3/4] 預熱與運行測試中 (持續運行 60 秒，每 10 秒快照一次)...

--- 壓測持續 10 秒後的資源佔用快照 ---
NAME                   CPU %     MEM USAGE / LIMIT     BLOCK I/O     NET I/O
benchmark-log-tester   111.64%   13.04MiB / 42.81GiB   0B / 0B       14kB / 126B
benchmark-fluent-bit   6.41%     128.9MiB / 42.81GiB   0B / 0B       13.6kB / 126B
benchmark-vector       204.82%   304.2MiB / 42.81GiB   0B / 442kB    13.5kB / 126B
benchmark-filebeat     239.41%   126.4MiB / 42.81GiB   0B / 2.75MB   13.1kB / 126B

--- 壓測持續 20 秒後的資源佔用快照 ---
NAME                   CPU %     MEM USAGE / LIMIT     BLOCK I/O     NET I/O
benchmark-log-tester   110.30%   13.46MiB / 42.81GiB   0B / 75.5MB   14.6kB / 126B
benchmark-fluent-bit   8.45%     134.8MiB / 42.81GiB   0B / 0B       14.2kB / 126B
benchmark-vector       199.59%   308MiB / 42.81GiB     0B / 848kB    14.1kB / 126B
benchmark-filebeat     244.94%   126.9MiB / 42.81GiB   0B / 2.75MB   13.6kB / 126B

--- 壓測持續 30 秒後的資源佔用快照 ---
NAME                   CPU %     MEM USAGE / LIMIT     BLOCK I/O     NET I/O
benchmark-log-tester   111.37%   14.5MiB / 42.81GiB    0B / 216MB    15.2kB / 126B
benchmark-fluent-bit   7.65%     136.7MiB / 42.81GiB   0B / 0B       14.7kB / 126B
benchmark-vector       201.24%   312.4MiB / 42.81GiB   0B / 1.36MB   14.7kB / 126B
benchmark-filebeat     233.03%   125MiB / 42.81GiB     0B / 2.78MB   14.2kB / 126B

--- 壓測持續 40 秒後的資源佔用快照 ---
NAME                   CPU %     MEM USAGE / LIMIT     BLOCK I/O     NET I/O
benchmark-log-tester   111.18%   15.5MiB / 42.81GiB    0B / 216MB    15.2kB / 126B
benchmark-fluent-bit   0.67%     112.6MiB / 42.81GiB   0B / 0B       14.7kB / 126B
benchmark-vector       204.88%   302.2MiB / 42.81GiB   0B / 1.8MB    14.7kB / 126B
benchmark-filebeat     241.88%   124MiB / 42.81GiB     0B / 2.78MB   14.2kB / 126B

--- 壓測持續 50 秒後的資源佔用快照 ---
NAME                   CPU %     MEM USAGE / LIMIT     BLOCK I/O     NET I/O
benchmark-log-tester   109.95%   16.13MiB / 42.81GiB   0B / 216MB    15.3kB / 126B
benchmark-fluent-bit   5.75%     137.4MiB / 42.81GiB   0B / 0B       14.7kB / 126B
benchmark-vector       203.35%   310.6MiB / 42.81GiB   0B / 2.24MB   14.7kB / 126B
benchmark-filebeat     246.17%   121.9MiB / 42.81GiB   0B / 2.78MB   14.3kB / 126B

--- 壓測持續 60 秒後的資源佔用快照 ---
NAME                   CPU %     MEM USAGE / LIMIT     BLOCK I/O     NET I/O
benchmark-log-tester   110.41%   17.06MiB / 42.81GiB   0B / 434MB    15.8kB / 126B
benchmark-fluent-bit   4.71%     137.4MiB / 42.81GiB   0B / 0B       15.3kB / 126B
benchmark-vector       197.45%   308.3MiB / 42.81GiB   0B / 2.68MB   15.3kB / 126B
benchmark-filebeat     242.25%   123.1MiB / 42.81GiB   0B / 2.81MB   14.8kB / 126B

[4/4] 統計各 Agent 吞吐與處理筆數：
Agent           Ingested (讀取筆數) Processed (完成/寫出) Status / 隊列
--------------- ------------------ ------------------ ------------
Fluent Bit      9382940            9218259            OK          
Vector          9641367            9640201            OK          
Filebeat        5082673            5081600            In-flight: 1073
```

---

## 綜合維度對比表

| 評測維度 | Fluent Bit (v5.1) | Vector (v0.58) | Filebeat (v8.19) |
| :--- | :--- | :--- | :--- |
| **完成處理筆數 (60s)** | **9,218,259** (921 萬筆) | **9,640,201** (964 萬筆) 🏆 | 5,081,600 (508 萬筆) |
| **平均 CPU 佔用** | 🟢 **4% ~ 8%** (極致省電) 🏆 | 🔴 **~200%** (約滿載 2 顆 Core) | 🔴 **~240%** (約滿載 2.4 顆 Core) |
| **記憶體佔用 (RSS)** | 🟢 **~137 MiB** | 🟡 **~308 MiB** | 🟢 **~123 MiB** 🏆 |
| **BLOCK I/O (Read)** | 🟢 **0B** (完全命中 Page Cache) | 🟢 **0B** (完全命中 Page Cache) | 🟢 **0B** (完全命中 Page Cache) |
| **BLOCK I/O (Write)**| 🟢 **0B** (純記憶體緩衝) | 🟡 **~2.68 MB** (持久化 Checkpoint) | 🟡 **~2.81 MB** (持久化 Registry) |
| **單位 CPU 處理效率**| 🔥 **最高 (冠絕群雄)** | 中等 (高吞吐換取高 CPU) | 偏低 |

---

## 關鍵技術深度剖析

### 1. Fluent Bit 的極致效能資源比（Performance-per-Watt）
* **突破單執行緒瓶頸**：在配置中開啟 `threaded: true` 與輸出端的 `workers: 2`，並將 Buffer 放大至 `buffer_chunk_size: 512k` / `buffer_max_size: 2M`，徹底釋放了 C 語言事件驅動架構的潛能。
* **驚人的 CPU 效率**：處理了超過 **921 萬筆** 日誌（僅微幅落後 Vector 4.3%），但 CPU 佔用僅維持在 **4% ~ 8%**（不到 0.1 顆 Core）。在大規模 Kubernetes 叢集幾百甚至數千個節點上作為 DaemonSet 運行時，累計節省的 CPU 成本非常驚人。

### 2. 磁碟 BLOCK I/O 秘密：為什麼需要 `file_cache_advise: false`？
在預設情況下，Fluent Bit 的 `tail` 插件會開啟 `file_cache_advise: true`。這意味著底層會呼叫 `posix_fadvise(..., POSIX_FADV_DONTNEED)`，主動向 Linux 核心建議「讀完就丟棄 Page Cache」，避免污染宿主機記憶體。
* **副作用**：在日誌高頻產生並持續 Tail 的場景下，丟棄快取迫使系統必須穿透到實體磁碟讀取，導致 BLOCK I/O Read 飆高到數 GB。
* **優化方案**：在配置中明確指定 `file_cache_advise: false` 後，Fluent Bit 成功完全命中 Linux 核心 Page Cache，**BLOCK I/O Read 直接降至 0B**，實現純記憶體高速讀取！

### 3. Vector：專為高吞吐與資料清洗設計的猛獸
* **吞吐之王**：以 **964 萬筆** 拿下最高吞吐量，且 100% 即時完成，零隊列積壓。Rust 的 Tokio 非同步模型與 VRL 解析能力極為卓越。
* **資源取向**：Vector 設計初衷是充分榨乾可用硬體，主動吃滿約 2 顆 CPU 核心（~200% CPU），記憶體穩定在約 308 MiB。非常適合部署為企業級「日誌中繼彙總層（Aggregator）」。

### 4. Filebeat：Go 語言傳統架構的瓶頸
* Filebeat 在 60 秒內消耗了全場最高的 CPU（**~240%**，吃滿 2.4 顆 Core），但最終完成量僅 **508 萬筆**（約前兩者的 53%~55%），且隊列仍有 1,000+ 筆 in-flight 事件在延遲中。
* 儘管其設定簡單、與 Elastic 生態無縫整合，但在極限吞吐下，Go 語言的 GC 資源回收與 Channel 調度開銷，明顯比起 C (Fluent Bit) 與 Rust (Vector) 更加沉重。

---

## 結論與選型建議

1. **邊緣與節點級收集 (Node-level DaemonSet)**：首選 **Fluent Bit**。以不到 10% 的 CPU 跑出超過 900 萬筆吞吐，省資源、零磁碟讀取，是節約基礎設施成本的最佳利器。
2. **日誌中繼彙總層 (Aggregator)**：首選 **Vector**。具備強大的 VRL 清洗能力、多核心並行吞吐能力與最完備的 Disk Buffer 背壓保護。
3. **Elastic Stack 重度使用者**：選 **Filebeat / Elastic Agent**。若吞吐量在一般中等規模且仰賴 Kibana Fleet 統一管理，生態原生優勢依然不可取代。
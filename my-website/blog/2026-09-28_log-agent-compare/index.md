---
title: "Fluent Bit vs Vector vs Elastic Agent 深度對比"
description: "全面比較雲原生主流日誌收集工具 Fluent Bit、Vector 與 Elastic Agent 的核心架構、GitHub 熱度、Parser 資料處理能力、資源開銷與實戰 Benchmark"
tags: [logging, devops, k8s, benchmark]
---

<!-- truncate -->

在雲原生與分散式微服務架構下，日誌（Logs）與可觀測性資料的收集與傳遞是系統穩定性的基石。當前市場上最受關注的三款日誌收集與管線工具分別為：


1. **Fluent Bit** ([fluentbit.io](https://fluentbit.io))：CNCF 畢業專案，以 C 語言打造的超輕量級日誌與指標處理器。
2. **Vector** ([vector.dev](https://vector.dev))：Datadog 主導維護，以 Rust 打造的高效能、記憶體安全可觀測性資料管線（Pipeline）。
3. **Elastic Agent** ([elastic.co/elastic-agent](https://www.elastic.co/elastic-agent))：Elastic 官方新一代整合型 Agent，統一管理 Logs、Metrics、Traces 與 Security。

本文將從**核心定位、社群熱度 (GitHub Stars)、資源消耗、Parser 支援與正規化、生態支援、管理運維**等多個維度展開深入對比，並提供**三者使用 stdin/stdout 進行 Nginx 日誌解析的實戰設定**、**Vector 客製化 Nginx 格式的解析技巧**，以及一套**可直接在本機 Docker 運行的實際 Benchmark 測試方案**。


---

## 一、三者核心概述與社群熱度 (GitHub Stars)

| 評比維度 | Fluent Bit | Vector | Elastic Agent |
|:-----|:-----------|:-------|:--------------|
| **官方網站** | [fluentbit.io](https://fluentbit.io) | [vector.dev](https://vector.dev) | [elastic.co/elastic-agent](https://www.elastic.co/elastic-agent) |
| **GitHub Repo** | [`fluent/fluent-bit`](https://github.com/fluent/fluent-bit) | [`vectordotdev/vector`](https://github.com/vectordotdev/vector) | [`elastic/elastic-agent`](https://github.com/elastic/elastic-agent)<br>*(核心底層* [`*elastic/beats*`](https://github.com/elastic/beats)*)* |
| **GitHub Stars** | **\~8,100+** | **\~22,600+** | **\~280+** *(Beats 為 \~12,700+)* |
| **GitHub Forks** | \~2,000+   | \~2,300+ | \~270+ *(Beats 為 \~5,000+)* |
| **維護機構** | CNCF (畢業專案) / Chronosphere | Datadog (收購 Timber.io 後主導開源) | Elastic N.V.  |
| **社群氛圍與動能** | 雲原生/K8s 領域事實標準，社群基礎穩固 | 近年熱度最高、增長最快的 Rust 項目之一 | 企業級生態龐大，但專案偏向原廠產品交付 |

### 1. Fluent Bit

* **核心定位**：專注於「邊緣與節點級收集」，以極低資源佔用聞名，是 Kubernetes DaemonSet 的事實標準之一。
* **技術特性**：基於 **C 語言** 與非同步事件驅動架構（epoll/kqueue），Binary 體積小、啟動速度以毫秒計、記憶體佔用極低（15MB \~ 50MB）。
* **生態中立**：CNCF 畢業專案，支援數十種 Input/Output 外掛，對接各大雲端（AWS CloudWatch、GCP Logging、Azure Monitor）與開源後端（Loki、Kafka、ES）。

### 2. Vector

* **核心定位**：定位為「端到端可觀測性資料管線（Observability Data Pipeline）」，既可作為輕量 Node Agent，也能作為集中式彙總轉發層（Aggregator）。
* **技術特性**：基於 **Rust 語言** 與 Tokio 非同步運行時，無 GC 停頓，兼顧極致效能與嚴格記憶體安全。
* **社群爆發力**：GitHub Stars 已突破 2.2 萬，深受追求高吞吐、低延遲與現代資料架構（如 ClickHouse、Kafka）工程師喜愛。

### 3. Elastic Agent

* **核心定位**：Elasticsearch / Kibana 生態專屬的「單一統一 Agent」，旨在整合並取代以往分散的 Filebeat、Metricbeat、Packetbeat 等 Beats 家族。
* **技術特性**：由 **Go 語言 + C++** 編寫，內部封裝了 Beats 引擎與 Elastic Endpoint Security 防護模組。
* **定位轉變**：Repo Stars 數較少是因為 Elastic Agent 作為 Elastic Stack 的整合包裝層，社群互動主要集中在 Kibana / Beats 原專案與商業社群中。


---

## 二、Parser 支援度與資料正規化能力評比

日誌收集最核心的一環在於如何將非結構化文字（如 Nginx、Syslog、應用程式日誌）轉換為結構化（JSON/Key-Value）並賦予明確型別。

| 解析與正規化維度 | Fluent Bit | Vector | Elastic Agent |
|:---------|:-----------|:-------|:--------------|
| **主要解析機制** | 內建 Filter (Parser, Regex, JSON) + Lua / WASM | **VRL (Vector Remap Language)** 原生表達式 | Agent 端 Processors (Dissect/Grok) 或 **ES Ingest Pipeline** |
| **開箱即用 Parser** | 內建常見 Parser（Nginx, Apache, Syslog, Docker, CRI, JSON） | 內建專用解析函數（`parse_nginx_log`、`parse_syslog`、`parse_common_log`、`parse_grok` 等） | 透過 Elastic Integration 自動載入預建 Ingest Pipelines |
| **進階清洗與型別轉換** | 需搭配多重 Filters 或寫 Lua 腳本 | **極強**（VRL 支援型別轉型、運算、條件判斷、動態賦值） | Agent 端較簡略，主要依賴 ES 端 Painless 腳本與 Ingest Processors |
| **標準規範對齊** | 自訂欄位名稱，需手動統一命名規範 | 靈活自由，可透過 VRL 輕鬆轉化為任何標準（如 OTel） | **原生深度綁定 ECS (Elastic Common Schema)** |
| **安全性與錯誤處理** | Regex 需防範 ReDoS；Lua 腳本有沙盒開銷 | VRL 具編譯期檢查與防崩潰機制（`!` 標記錯誤傳播） | Ingest Pipeline 具備 `on_failure` 容錯處理 |

* **Fluent Bit**：解析依靠靜態配置的 Regex 或 JSON parser。對於單純格式效率極高；但如果遇到日誌有多種變體、需要條件跳轉或型別轉換（例如將字串轉為整數），配置會變得繁複，往往必須動用 Lua 外掛。
* **Vector**：**在三者中具備最強大的本地端解析能力**。VRL（Vector Remap Language）是一套專為 Observability 設計的高效 DSL，一行語法即可完成 Nginx 日誌解析，並自動將狀態碼轉為整數、時間戳轉為 ISO8601，且能在解析失敗時提供安全的 fallback 機制。
* **Elastic Agent**：核心思維是「端點快速採集，後端統一正規化」。日誌進入 Elasticsearch 時由 Ingest Pipeline 自動對齊到 ECS 規範。如果在 Edge 端就要完成所有清洗，需要在 Agent 端寫 `dissect` 或 `grok` processor。


---

## 三、實戰範例：Nginx 日誌解析與正規化 (stdin -> stdout)

本節針對三款工具提供具體的測試配置。 **目標**：透過 `stdin` 輸入一筆標準 Nginx Combined 格式日誌，經由各工具的 Parser 完成正規化與欄位解析後，輸出為 JSON 格式至 `stdout`。

### 測試日誌樣本 (Nginx Combined Format)

```text
192.168.1.100 - - [28/Sep/2026:12:00:00 +0800] "GET /api/v1/health HTTP/1.1" 200 612 "https://example.com" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
```


---

### 1. Fluent Bit 設定與執行

Fluent Bit 採用 `parsers.conf` 定義正則解析規則，並在主配置中使用 `parser` filter 提取欄位。

#### 步驟 A：建立 `parsers.conf`

```ini
[PARSER]
    Name        nginx_combined
    Format      regex
    Regex       ^(?<remote_addr>[^ ]*) - (?<remote_user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<request_uri>[^\"]*?)(?: +(?<http_version>\S+))?)?" (?<status>[^ ]*) (?<body_bytes_sent>[^ ]*)(?: "(?<http_referer>[^\"]*)" "(?<http_user_agent>[^\"]*)")?$
    Time_Key    time
    Time_Format %d/%b/%Y:%H:%M:%S %z
```

#### 步驟 B：建立主設定檔 `fluent-bit.yaml`

```yaml
service:
  parsers_file: parsers.conf

pipeline:
  inputs:
    - name: stdin
  filters:
    - name: parser
      match: "*"
      key_name: log
      parser: nginx_combined
      reserve_data: false
  outputs:
    - name: stdout
      match: "*"
      format: json_lines
```

#### 執行指令：

```bash
echo '192.168.1.100 - - [28/Sep/2026:12:00:00 +0800] "GET /api/v1/health HTTP/1.1" 200 612 "https://example.com" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"' | fluent-bit -c fluent-bit.yaml
```


---

### 2. Vector 設定與執行 (標準格式)

Vector 使用原生 VRL 函數 `parse_nginx_log`，能自動識別標準 Combined 格式，並將數值型態（如 status、size）自動轉型為整數。

#### 建立設定檔 `vector.yaml`

```yaml
sources:
  in:
    type: stdin

transforms:
  parse_nginx:
    type: remap
    inputs:
      - in
    source: |
      # 使用內建 Nginx Combined 解析器
      parsed = parse_nginx_log!(.message, "combined")
      
      # 將解析出的欄位合併至根物件，並保留結構化資料
      . = merge(., parsed)
      
      # 移除原始文字訊息
      del(.message)

sinks:
  out:
    type: stdout
    inputs:
      - parse_nginx
    encoding:
      codec: json
```

#### 執行指令：

```bash
echo '192.168.1.100 - - [28/Sep/2026:12:00:00 +0800] "GET /api/v1/health HTTP/1.1" 200 612 "https://example.com" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"' | vector -c vector.yaml
```


---

### 2.1 進階實戰：Vector 解析 Nginx 客製化格式 (Custom Format)

在實際生產環境中，企業通常會在 Nginx `log_format` 中加入自訂欄位，例如 `$request_time`（請求耗時）、`$upstream_response_time`（後端響應時間）、`$http_x_forwarded_for` 等。

> **注意**：Vector 的 `parse_nginx_log` **僅支援固定格式**（`"combined"` 或 `"error"`）。一旦日誌包含自訂欄位，直接使用 `parse_nginx_log` 會引發解析失敗。

針對客製化日誌，Vector 提供了三種靈活且高效的解析方式：

#### 客製化格式範例

```nginx
log_format custom '$remote_addr - $remote_user [$time_local] '
                  '"$request" $status $body_bytes_sent '
                  '"$http_referer" "$http_user_agent" '
                  '$request_time "$upstream_response_time"';
```

樣本：

```text
192.168.1.100 - - [28/Sep/2026:12:00:00 +0800] "GET /api/v1/health HTTP/1.1" 200 612 "https://example.com" "Mozilla/5.0" 0.025 "0.018"
```

#### 寫法 A：使用 `parse_regex`（具名捕獲組，推薦做法）

```yaml
transforms:
  parse_custom_nginx:
    type: remap
    inputs:
      - in
    source: |
      pattern = r'^(?P<client>[^ ]+) - (?P<user>[^ ]+) \[(?P<timestamp>[^\]]+)\] "(?P<method>\S+) (?P<path>\S+) (?P<protocol>[^"]+)" (?P<status>\d+) (?P<size>\d+) "(?P<referer>[^"]*)" "(?P<agent>[^"]*)" (?P<request_time>[^ ]+) "(?P<upstream_response_time>[^"]*)"'
      
      parsed, err = parse_regex(.message, pattern)
      if err != null {
        .error = err
      } else {
        . = merge(., parsed)
        
        # 型別強制轉換 (Type Casting)
        .status = to_int!(.status)
        .size = to_int!(.size)
        .request_time = to_float!(.request_time)
        
        # 處理可選或特殊值 (如 upstream_response_time 為 "-" 時轉為 null)
        if .upstream_response_time != "-" && .upstream_response_time != "" {
          .upstream_response_time = to_float!(.upstream_response_time)
        } else {
          .upstream_response_time = null
        }
        
        # 時間戳標準化為 UTC RFC3339
        .timestamp = parse_timestamp!(.timestamp, "%d/%b/%Y:%H:%M:%S %z")
        
        del(.message)
      }
```

#### 寫法 B：使用 `parse_grok`

```yaml
transforms:
  parse_custom_nginx_grok:
    type: remap
    inputs:
      - in
    source: |
      pattern = "%{IP:client} - (%{USER:user}|-) \\[%{HTTPDATE:timestamp}\\] \"%{WORD:method} %{URIPATHPARAM:path} %{NOTSPACE:protocol}\" %{INT:status:int} %{INT:size:int} \"(%{DATA:referer}|-)\" \"%{DATA:agent}\" %{NUMBER:request_time:float} \"(%{NUMBER:upstream_response_time:float}|-)\""
      
      parsed, err = parse_grok(.message, pattern)
      if err == null {
        . = merge(., parsed)
        .timestamp = parse_timestamp!(.timestamp, "%d/%b/%Y:%H:%M:%S %z")
        del(.message)
      }
```

#### 寫法 C：雲原生最佳實踐 —— Nginx 直出 JSON

與其在 Agent 端消耗 CPU 運算跑正規表達式，現代架構更建議**在 Nginx 端直接配置 JSON 格式輸出**：

```nginx
log_format json_analytics escape=json '{'
  '"time_local":"$time_local",'
  '"client_ip":"$remote_addr",'
  '"method":"$request_method",'
  '"uri":"$request_uri",'
  '"status":$status,'
  '"bytes":$body_bytes_sent,'
  '"request_time":$request_time,'
  '"upstream_time":"$upstream_response_time",'
  '"agent":"$http_user_agent"'
'}';
```

在 Vector 端的 VRL 解析只需極簡的一行，效能最高且維護成本最低（零正則開銷）：

```yaml
transforms:
  parse_json_nginx:
    type: remap
    inputs:
      - in
    source: |
      . = merge(., parse_json!(.message))
      del(.message)
```


---

### 3. Elastic Agent (Standalone / Filebeat 模式) 設定與執行

Elastic Agent 在獨立（Standalone）模式下，底層以 Filebeat 引擎執行。透過 `dissect` 處理器快速拆解字串，並依照 **ECS (Elastic Common Schema)** 規範進行欄位命名，最後輸出至 Console。

```yaml
filebeat.inputs:
  - type: stdin
    enabled: true
    processors:
      - dissect:
          tokenizer: '%{client.ip} - - [%{@timestamp}] "%{http.request.method} %{url.path} %{http.version}" %{http.response.status_code} %{http.response.body.bytes} "%{http.request.referrer}" "%{user_agent.original}"'
          field: "message"
          target_prefix: ""
      - convert:
          fields:
            - {from: "http.response.status_code", type: "integer"}
            - {from: "http.response.body.bytes", type: "integer"}
      - drop_fields:
          fields: ["message"]

output.console:
  pretty: true
```


---

## 四、核心效能與資源開銷對比

| 指標  | Fluent Bit | Vector | Elastic Agent |
|:----|:-----------|:-------|:--------------|
| **開發語言** | C (無 GC)   | Rust (無 GC) | Go + C++ (Go GC 機制) |
| **記憶體佔用** | **最低** (\~15MB - 50MB) | **低至中** (\~30MB - 120MB) | **較高** (\~150MB - 500MB+) |
| **CPU 效率** | 極高，但在複雜正則與 Lua 處理時開銷上升 | 極高，Tokio 多核心利用率佳，VRL 編譯期優化 | 中等，Go GC 與多進程/模組架構有固定負擔 |
| **高吞吐抗壓** | 適合常態邊緣傳輸，爆量時需注意隊列設定 | 處理超高吞吐與複雜轉換時極具優勢 | 依賴底層 Beats 引擎，適合標準化傳輸 |
| **Binary 體積** | \~20MB - 40MB | \~40MB - 80MB | \~200MB - 400MB+ (含整合元件) |

* **Fluent Bit** 在資源受限場景（如邊緣運算、IoT、大型 K8s 叢集數千個節點）最具優勢，資源開銷可預測性強。
* **Vector** 憑藉 Rust 的並發優勢與零成本抽象，在高並發、高頻日誌過濾與富化（Enrichment）情境下展現出最高的單節點吞吐量。
* **Elastic Agent** 因單一二進位檔內聚合了多種背景功能（甚至包含資安監視模組），常駐記憶體與磁碟空間佔用明顯高於前兩者。


---

## 五、架構相容性與後端生態 (Ecosystem & Sinks)

### 1. Fluent Bit

* **定位中立**：身為 CNCF 專案，絕不綁定單一廠商。
* **支援目標**：完整支援 Elasticsearch, OpenSearch, AWS CloudWatch, S3, Google Cloud Logging, Kafka, Loki, Prometheus, Datadog, Splunk 等近百種 Sinks。
* **雲原生標準**：各大雲端廠商（AWS EKS、GCP GKE、Azure AKS）官方文件與預設 Add-on 廣泛推薦採用 Fluent Bit 作為日誌轉發器。

### 2. Vector

* **定位中立**（雖然歸屬於 Datadog）：提供高度中立性，完全開源且不強制要求使用 Datadog。
* **支援目標**：支援 ClickHouse, Kafka, AWS S3, Loki, Elasticsearch, OpenSearch, Prometheus, Splunk 等，特別是與現代列式資料庫（如 **ClickHouse**）的對接支援非常成熟。
* **拓撲設計彈性**：支援 Agent 模式（收集）與 Aggregator 模式（集中緩衝與負載均衡），兩者使用同一套工具，簡化架構複雜度。

### 3. Elastic Agent

* **高度綁定 Elastic 生態**：專為 Elastic Stack 設計。
* **支援目標**：原生目的地為 Elasticsearch 或 Logstash，其他後端出口支援度有限（通常需經由 Logstash 或 Kafka 轉發）。
* **生態價值**：若整個監控體系架構在 Elastic Stack 上，Elastic Agent 具備無可比擬的優勢：自動套用 ECS（Elastic Common Schema）、自動建立 Index Lifecycle Management (ILM)、一鍵安裝專屬 Kibana Dashboard。


---

## 六、維運管理與配置體驗 (Operations & Management)

| 項目  | Fluent Bit | Vector | Elastic Agent |
|:----|:-----------|:-------|:--------------|
| **配置格式** | Classic (.conf) 或 YAML | TOML, YAML, JSON | YAML (或由 Fleet 控制台自動生成) |
| **集中管理** | 主要透過 GitOps (K8s ConfigMap, Helm, Ansible) | 主要透過 GitOps (K8s ConfigMap, Helm, Vector Topologies) | **Fleet UI 集中管理**（一鍵推送原則與升級） |
| **熱重載 (Reload)** | 支援訊號重載 (`SIGHUP` / HTTP API)，但部分外掛重載有限制 | 支援動態配置熱重載 (`SIGHUP` / API)，無中斷更新管線 | 透過 Fleet 伺服器即時推播，節點自動同步新配置 |
| **監控與除錯** | 提供 Prometheus Metrics Endpoint 與除錯日誌 | 提供內建 GraphQL/HTTP API、Prometheus Metrics 與 `vector tap` 即時觀察資料流 | 整合於 Kibana Fleet 頁面，即時掌握所有 Agent 健全狀態與錯誤日誌 |


---

## 七、全方位綜合比較矩陣

| 比較維度 | Fluent Bit | Vector | Elastic Agent |
|:-----|:-----------|:-------|:--------------|
| **GitHub Stars** | ⭐️ 8,100+  | ⭐️ 22,600+ | ⭐️ 280+ *(Beats 12,700+)* |
| **專案主體** | CNCF (畢業專案) | Datadog (開源維護) | Elastic N.V.  |
| **主要定位** | 邊緣輕量級採集器   | 端到端高效能資料管線 (Agent / Aggregator) | Elastic 全功能統一主機/容器 Agent |
| **核心語言** | C          | Rust   | Go + C++      |
| **記憶體佔用** | ⭐️⭐️⭐️⭐️⭐️ (15 - 50 MB) | ⭐️⭐️⭐️⭐️ (30 - 120 MB) | ⭐️⭐️ (150 - 500 MB+) |
| **CPU 效能** | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️        |
| **Parser / 轉換能力** | ⭐️⭐️⭐️ (正則 / 需依賴 Lua) | ⭐️⭐️⭐️⭐️⭐️ (**VRL 極具優勢**) | ⭐️⭐️⭐️⭐️ (原生整合 ECS / ES Pipeline) |
| **多後端中立性** | ⭐️⭐️⭐️⭐️⭐️ (極高，無特定廠商傾向) | ⭐️⭐️⭐️⭐️⭐️ (極高，無特定廠商傾向) | ⭐️⭐️ (強烈傾向 Elastic 生態) |
| **K8s 支援度** | ⭐️⭐️⭐️⭐️⭐️ (業界標準) | ⭐️⭐️⭐️⭐️ (成熟) | ⭐️⭐️⭐️⭐️ (依賴 Elastic Operator / Fleet) |
| **集中管控體驗** | ⭐️⭐️⭐️ (依賴外部 GitOps 工具) | ⭐️⭐️⭐️ (依賴外部 GitOps 工具) | ⭐️⭐️⭐️⭐️⭐️ (原生 Fleet UI 一站式維運) |
| **涵蓋範疇** | Logs, Metrics, Traces | Logs, Metrics, Traces | Logs, Metrics, APM, Security (EDR/XDR) |
| **背壓控制與緩衝** | 記憶體 Buffer + 磁碟檔案儲存 | 記憶體 Buffer + 高效能磁碟佇列 (Disk Buffer) | 內部記憶體佇列 + Spool to disk |
| **學習成本與上手門檻** | ⭐️⭐️⭐️ (中等，配置語法需熟悉多種 Plugin 語法，進階處理需寫 Lua) | ⭐️⭐️⭐️⭐️ (低至中等，文件優異，VRL 直覺好寫且有除錯工具) | ⭐️⭐️⭐️⭐️⭐️ (極低，透過 Fleet Web UI 點選整合，但自訂 Ingest Pipeline 偏繁瑣) |


---

## 八、實戰 Benchmark：本機 Docker Compose 效能測試

為了真實量化三者的資源消耗與吞吐能力，我們設計了一套以 Docker Compose 與 `mingrammer/flog` 為核心的自動化基準壓測方案。

本測試針對三大 Agent 進行了持續 **60 秒、累積超過 960 萬筆高頻 JSON 日誌** 的極限性能測試，全面記錄 **CPU 使用率、記憶體 (RSS)、BLOCK I/O 零磁碟讀取、以及每秒處理筆數**。

> 👉 **完整測試環境、自動化腳本與 60 秒深度數據分析請參閱專屬評測專文：**  
> 🔗 **[Fluent Bit vs Vector vs Filebeat 效能壓測評測](../2026-09-28_log-agent-benchmark/index.md)**

### 重點結論快覽

* **Fluent Bit (C)**：在調優 `file_cache_advise: false` 與啟用 `threaded: true` 後，以 **不到 10% 的極低 CPU 消耗（4% ~ 8%）** 處理了超過 **921 萬筆** 日誌，實現完全零磁碟讀取（0B Block I/O），效能資源比（Performance-per-Watt）最為優異。
* **Vector (Rust)**：以 **964 萬筆** 拿下吞吐量第一，零隊列延遲積壓，但主動拉滿約 2 顆 CPU 核心（~200% CPU）與 308 MiB 記憶體，非常適合部署在集中式彙總轉發層（Aggregator）。
* **Filebeat (Go)**：CPU 佔用最高（~240%），但吞吐量僅有前兩者的約一半（508 萬筆），在高頻百萬級處理下受限於 Go 的 GC 與通道開銷。

---

## 九、選型總結與建議


1. **優先選擇 Fluent Bit 的情境**：
   * 大型 Kubernetes 叢集（數百至數千節點）的 DaemonSet 採集。
   * 資源極度受限的邊緣運算 / IoT 裝置（記憶體 < 512MB）。
   * 僅需標準日誌收集、加註 K8s 標籤並轉發至多後端。
2. **優先選擇 Vector 的情境**：
   * 日誌量巨大，需要高效能資料清洗、正規化、動態路由或敏感資料（PII）脫敏。
   * 欲架構企業級「日誌中繼彙總層（Aggregator）」，需要可靠的 Disk Buffer 與背壓保護。
   * 後端使用 ClickHouse、Grafana Loki、Kafka 或 S3 等非 Elastic 體系。
3. **優先選擇 Elastic Agent 的情境**：
   * 企業已深度投資 Elastic Stack (Elastic Cloud / Enterprise)。
   * 維運團隊需要透過 Kibana Fleet Web UI 進行一站式無代碼集中管理、原則派送與升級。
   * 需要整合日誌、系統指標與主機安全性監控（EDR/XDR）。
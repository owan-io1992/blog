#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "=========================================================="
echo "      Log Agent Benchmark: Fluent Bit vs Vector vs Beats"
echo "=========================================================="

echo "[1/4] 清理舊環境與 Volume..."
docker compose down -v 2>/dev/null || true

echo "[2/4] 啟動測試環境 (log-tester, fluent-bit, vector, filebeat)..."
docker compose up -d

echo "[3/4] 預熱與運行測試中 (持續運行 60 秒，每 10 秒快照一次)..."
for i in {1..6}; do
  sleep 10
  echo ""
  echo "--- 壓測持續 $((i * 10)) 秒後的資源佔用快照 ---"
  docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.BlockIO}}\t{{.NetIO}}" benchmark-log-tester benchmark-fluent-bit benchmark-vector benchmark-filebeat
done

echo ""
echo "[4/4] 統計各 Agent 吞吐與處理筆數："

# 解析 Fluent Bit 指標
fb_metrics=$(curl -s http://localhost:2020/api/v1/metrics/prometheus 2>/dev/null || true)
fb_in=$(echo "$fb_metrics" | grep '^fluentbit_input_records_total' | head -n1 | awk '{print $2}')
fb_out=$(echo "$fb_metrics" | grep '^fluentbit_output_proc_records_total' | head -n1 | awk '{print $2}')

# 解析 Vector 指標 (過濾實際 app_log 與 blackhole 組件)
vec_metrics=$(curl -s http://localhost:9090/metrics 2>/dev/null || true)
vec_in=$(echo "$vec_metrics" | grep '^vector_component_received_events_total{component_id="app_log"' | awk '{print $2}')
vec_out=$(echo "$vec_metrics" | grep '^vector_component_sent_events_total{component_id="blackhole"' | awk '{print $2}')

# 解析 Filebeat 指標
fb_stats=$(curl -s http://localhost:5066/stats 2>/dev/null || true)
beat_added=$(echo "$fb_stats" | jq -r '(.filebeat.events.added // .libbeat.pipeline.events.added // "N/A")' 2>/dev/null || echo "N/A")
beat_done=$(echo "$fb_stats" | jq -r '(.filebeat.events.done // .libbeat.pipeline.events.done // "N/A")' 2>/dev/null || echo "N/A")
beat_active=$(echo "$fb_stats" | jq -r '(.filebeat.events.active // .libbeat.pipeline.events.active // "N/A")' 2>/dev/null || echo "N/A")

printf "%-15s %-18s %-18s %-12s\n" "Agent" "Ingested (讀取筆數)" "Processed (完成/寫出)" "Status / 隊列"
printf "%-15s %-18s %-18s %-12s\n" "---------------" "------------------" "------------------" "------------"
printf "%-15s %-18s %-18s %-12s\n" "Fluent Bit" "${fb_in:-N/A}" "${fb_out:-N/A}" "OK"
printf "%-15s %-18s %-18s %-12s\n" "Vector" "${vec_in:-N/A}" "${vec_out:-N/A}" "OK"
printf "%-15s %-18s %-18s %-12s\n" "Filebeat" "${beat_added:-N/A}" "${beat_done:-N/A}" "In-flight: ${beat_active:-0}"

echo ""
echo "=========================================================="
echo "測試成功！如需持續觀察即時效能，請執行："
echo "  docker stats benchmark-fluent-bit benchmark-vector benchmark-filebeat"
echo "測試結束清理環境："
echo "  docker compose down -v"
echo "=========================================================="

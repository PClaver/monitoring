#!/bin/bash
# Downloads community dashboards from grafana.com and places them
# in the provisioned dashboards folder so Grafana loads them automatically.

DASHBOARD_DIR="./grafana/dashboards"
mkdir -p "$DASHBOARD_DIR"

declare -A DASHBOARDS=(
  ["node-exporter.json"]="1860"       # Node Exporter Full (host CPU/memory/disk/network)
  ["docker-containers.json"]="193"    # Docker & System Dashboard (container metrics)
  ["nginx.json"]="13659"              # NGINX Prometheus Exporter (request counts, connections)
  ["loki-logs.json"]="15661"          # Loki & Promtail (log explorer)
)

for filename in "${!DASHBOARDS[@]}"; do
  id="${DASHBOARDS[$filename]}"
  echo "Downloading dashboard $id -> $filename..."
  curl -sf "https://grafana.com/api/dashboards/$id/revisions/latest/download" \
    -o "$DASHBOARD_DIR/$filename"
  if [ $? -eq 0 ]; then
    echo "  OK"
  else
    echo "  FAILED - check your internet connection or dashboard ID $id"
  fi
done

echo ""
echo "Done. Restart Grafana to pick up new dashboards:"
echo "  docker compose restart grafana"

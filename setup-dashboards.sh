#!/bin/bash
# Downloads community dashboards from grafana.com and patches the datasource
# references so they match our provisioned datasource names.

DASHBOARD_DIR="./grafana/dashboards"
mkdir -p "$DASHBOARD_DIR"

declare -A DASHBOARDS=(
  ["node-exporter.json"]="1860"    # Node Exporter Full (host CPU/memory/disk/network)
  ["docker-containers.json"]="193" # Docker & System Dashboard (container metrics)
  ["nginx.json"]="13659"           # NGINX Prometheus Exporter (requests, connections)
  ["loki-logs.json"]="15661"       # Loki & Promtail (log explorer)
)

for filename in "${!DASHBOARDS[@]}"; do
  id="${DASHBOARDS[$filename]}"
  echo "Downloading dashboard $id -> $filename..."
  curl -sf "https://grafana.com/api/dashboards/$id/revisions/latest/download" \
    -o "$DASHBOARD_DIR/$filename"

  if [ $? -ne 0 ]; then
    echo "  FAILED - check your internet connection or dashboard ID $id"
    continue
  fi

  # Community dashboards reference datasources by name or UID.
  # Patch them to use our provisioned Prometheus datasource name.
  sed -i 's/"uid": *"[^"]*prometheus[^"]*"/"uid": "prometheus"/gi' "$DASHBOARD_DIR/$filename" 2>/dev/null || true
  sed -i 's/"datasource": *"[^"]*Prometheus[^"]*"/"datasource": "Prometheus - Server 1"/gi' "$DASHBOARD_DIR/$filename" 2>/dev/null || true
  sed -i 's/"datasource": *"[^"]*Loki[^"]*"/"datasource": "Loki"/gi' "$DASHBOARD_DIR/$filename" 2>/dev/null || true

  echo "  OK"
done

echo ""
echo "Done. Restart Grafana to pick up new dashboards:"
echo "  docker compose restart grafana"

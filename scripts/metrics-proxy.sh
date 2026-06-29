#!/usr/bin/env bash
set -euo pipefail

if command -v op &>/dev/null && [ -z "${PROM_USER:-}" ]; then
  PROM_USER=$(op read "op://private/grafana-cloud/GRAFANA_CLOUD_PROMETHEUS_USER" 2>/dev/null || true)
  PROM_TOKEN=$(op read "op://private/grafana-cloud/GRAFANA_CLOUD_API_TOKEN" 2>/dev/null || true)
  PROM_URL=$(op read "op://private/grafana-cloud/GRAFANA_CLOUD_PROMETHEUS_URL" 2>/dev/null || true)
fi

export PROM_USER PROM_TOKEN PROM_URL
exec python3 "$(dirname "$0")/metrics-proxy.py"

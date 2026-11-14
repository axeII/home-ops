#!/usr/bin/env bash
# Install or update Grafana Alloy on the Proxmox host and load alloy/config.alloy.
# Usage: ./deploy.sh
set -euo pipefail

PVE="root@192.168.69.80"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() { printf "\033[0;32m==> %s\033[0m\n" "$*"; }

log "Installing Alloy from the Grafana apt repository (no-op if present)..."
ssh "${PVE}" 'set -euo pipefail
if ! dpkg -s alloy >/dev/null 2>&1; then
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
  echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
    > /etc/apt/sources.list.d/grafana.list
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq alloy
fi
# The journal is readable by systemd-journal and adm.
usermod -aG systemd-journal,adm alloy'

log "Validating and installing the config..."
scp -q "${SCRIPT_DIR}/alloy/config.alloy" "${PVE}:/etc/alloy/config.alloy.new"
ssh "${PVE}" 'set -euo pipefail
alloy fmt /etc/alloy/config.alloy.new >/dev/null
mv /etc/alloy/config.alloy.new /etc/alloy/config.alloy
systemctl enable -q alloy
systemctl restart alloy
sleep 5
systemctl is-active alloy'

log "Pointing the Proxmox metric server at Alloy (no-op if present)..."
ssh "${PVE}" 'pvesh get /cluster/metrics/server/alloy >/dev/null 2>&1 \
  || pvesh create /cluster/metrics/server/alloy --type opentelemetry \
       --server 127.0.0.1 --port 4318 --otel-protocol http --otel-compression none'

log "Done. Check: ssh ${PVE} journalctl -u alloy -n 30"

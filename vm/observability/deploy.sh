#!/usr/bin/env bash
# Deploy observability stack to the VM
# Usage: ./deploy.sh [--dry-run]
set -euo pipefail

VM_IP="192.168.3.3"
VM_USER="akira"
REMOTE_DIR="/opt/observability"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() { printf "\033[0;32m==> %s\033[0m\n" "$*"; }
err() { printf "\033[0;31m==> ERROR: %s\033[0m\n" "$*" >&2; exit 1; }

# Check VM connectivity
log "Checking VM connectivity..."
ssh -o ConnectTimeout=5 "${VM_USER}@${VM_IP}" "echo ok" >/dev/null 2>&1 \
  || err "Cannot reach VM at ${VM_IP}. Is it up?"

# Check Docker
log "Checking Docker..."
ssh "${VM_USER}@${VM_IP}" "docker --version && docker compose version" 2>/dev/null \
  || err "Docker not installed on VM"

# Create remote directory
log "Creating remote directory ${REMOTE_DIR}..."
ssh "${VM_USER}@${VM_IP}" "sudo mkdir -p ${REMOTE_DIR} && sudo chown ${VM_USER}:${VM_USER} ${REMOTE_DIR}"

# Sync files
log "Syncing config files..."
rsync -avz --delete \
  "${SCRIPT_DIR}/docker-compose.yaml" \
  "${SCRIPT_DIR}/.env.example" \
  "${SCRIPT_DIR}/prometheus/" \
  "${SCRIPT_DIR}/loki/" \
  "${SCRIPT_DIR}/grafana/" \
  "${SCRIPT_DIR}/caddy/" \
  "${VM_USER}@${VM_IP}:${REMOTE_DIR}/"

# Copy .env if it doesn't exist
ssh "${VM_USER}@${VM_IP}" "test -f ${REMOTE_DIR}/.env || cp ${REMOTE_DIR}/.env.example ${REMOTE_DIR}/.env"

if [[ "${1:-}" == "--dry-run" ]]; then
  log "Dry run complete. Files synced to ${VM_IP}:${REMOTE_DIR}"
  log "Edit .env on the VM, then run: ssh ${VM_USER}@${VM_IP} 'cd ${REMOTE_DIR} && docker compose up -d'"
  exit 0
fi

# Start services
log "Starting services..."
ssh "${VM_USER}@${VM_IP}" "cd ${REMOTE_DIR} && docker compose up -d"

# Wait for health
log "Waiting for services to start..."
sleep 10

# Verify
log "Verifying services..."
for svc in prometheus loki grafana caddy; do
  status=$(ssh "${VM_USER}@${VM_IP}" "docker inspect --format='{{.State.Status}}' ${svc}" 2>/dev/null)
  if [[ "$status" == "running" ]]; then
    log "  ${svc}: running"
  else
    err "  ${svc}: ${status}"
  fi
done

log "Deploy complete!"
log ""
log "Services available at:"
log "  Prometheus: http://metrics.internal"
log "  Loki:       http://logs.internal"
log "  Grafana:    http://grafana.internal"
log ""
log "Next steps:"
log "  1. Add DNS records to UniFi router:"
log "     - metrics.internal → ${VM_IP}"
log "     - logs.internal    → ${VM_IP}"
log "     - grafana.internal → ${VM_IP}"
log "  2. Verify from cluster: kubectl run curl-test --rm -it --image=curlimages/curl -- curl http://metrics.internal/-/healthy"

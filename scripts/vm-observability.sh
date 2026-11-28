#!/usr/bin/env bash
# Roll the observability VM forward to vm/observability as it is on main.
#
# Flux does not deploy vm/, so Renovate bumps to its docker-compose.yaml merge
# without reaching the VM. Run this after they merge.
#
#   scripts/vm-observability.sh          show what would change, change nothing
#   scripts/vm-observability.sh apply    show it, ask, then sync the files, pull,
#                                        recreate what changed, check the live
#                                        versions and delete replaced images
#
# REF=<git ref> deploys another ref (default origin/main); rolling back is
# REF=<older commit>. VM_HOST overrides the host. The VM's .env holds the
# Grafana admin password and is never read or written.
set -euo pipefail

VM_HOST="${VM_HOST:-akira@192.168.3.3}"
REMOTE_DIR="/opt/observability"
REF="${REF:-origin/main}"
SYNC=(docker-compose.yaml .env.example prometheus loki grafana caddy)

log() { printf '\033[0;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[0;33m==> %s\033[0m\n' "$*"; }
die() {
  printf '\033[0;31m==> ERROR: %s\033[0m\n' "$*" >&2
  exit 1
}
# -n: ssh would otherwise read stdin, eating the lists the loops below read.
vm() { ssh -n -o ConnectTimeout=5 "$VM_HOST" "cd $REMOTE_DIR && $*"; }

# Prints the version a service reports over HTTP, asked from inside the caddy
# container. Loki's /ready is not used: with the pattern ingester enabled it
# can stay 503 while Loki serves queries.
live_version() {
  local out
  case "$1" in
  prometheus)
    out="$(vm "docker exec caddy wget -qO- -T 5 http://prometheus:9090/api/v1/status/buildinfo")" &&
      jq -r .data.version <<<"$out"
    ;;
  loki)
    out="$(vm "docker exec caddy wget -qO- -T 5 http://loki:3100/loki/api/v1/status/buildinfo")" &&
      jq -r .version <<<"$out"
    ;;
  grafana)
    out="$(vm "docker exec caddy wget -qO- -T 5 http://grafana:3000/api/health")" &&
      jq -r .version <<<"$out"
    ;;
  caddy) vm "docker exec caddy caddy version" | awk '{print $1}' ;;
  *) return 2 ;;
  esac
}

mode="${1:-diff}"
[[ "$mode" == diff || "$mode" == apply ]] || die "usage: $0 [diff|apply]"

repo="$(git rev-parse --show-toplevel)"
vm true 2>/dev/null || die "cannot reach $VM_HOST:$REMOTE_DIR (is the VPN up?)"

if [[ "$REF" == origin/* ]]; then
  git -C "$repo" fetch --quiet origin "${REF#origin/}"
fi
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git -C "$repo" archive "$REF" vm/observability | tar -x -C "$tmp"
src="$tmp/vm/observability"
log "Comparing $VM_HOST:$REMOTE_DIR with $REF ($(git -C "$repo" rev-parse --short "$REF"))"

# ── Images: what runs now against what the compose file asks for ──────────────
want="$(yq '.services | to_entries[] | .key + " " + .value.image' "$src/docker-compose.yaml")"
have="$(vm "docker compose ps -a --format '{{.Service}} {{.Image}}'")"
images_changed=" "
pending=0

echo "Images:"
while read -r svc img; do
  cur="$(awk -v s="$svc" '$1 == s {print $2}' <<<"$have")"
  if [[ "$cur" == "$img" ]]; then
    printf '  %-11s %s\n' "$svc" "$img"
  else
    printf '  %-11s %s -> %s\n' "$svc" "${cur:-not running}" "$img"
    images_changed+="$svc "
    pending=1
  fi
done <<<"$want"
while read -r svc img; do
  [[ -z "$svc" ]] && continue
  if ! awk -v s="$svc" '$1 == s {found = 1} END {exit !found}' <<<"$want"; then
    printf '  %-11s %s -> removed\n' "$svc" "$img"
    pending=1
  fi
done <<<"$have"

# ── Files: config on the VM against the ref ──────────────────────────────────
# -c compares content: git archive stamps every file with the commit time.
itemized="$(cd "$src" && rsync -rcni --delete "${SYNC[@]}" "$VM_HOST:$REMOTE_DIR/")"
restart=()
files_changed=0

echo "Files:"
while read -r flags path; do
  [[ -z "$flags" ]] && continue
  case "$flags" in
  \*deleting) echo "  delete $path" ;;
  \<f+*)
    echo "  new    $path"
    diff -u /dev/null "$src/$path" | sed 's/^/    /' || true
    ;;
  \<f*)
    echo "  change $path"
    # shellcheck disable=SC2029  # the path is meant to expand locally
    diff -u --label "vm:$path" --label "$REF:$path" \
      <(ssh -n "$VM_HOST" cat "$REMOTE_DIR/$path") "$src/$path" | sed 's/^/    /' || true
    ;;
  *) continue ;;
  esac
  pending=1
  files_changed=1
  svc="${path%%/*}"
  # A bind-mounted config change does not recreate the container, so restart
  # it, unless a new image recreates it anyway.
  if [[ "$path" == */* && "$images_changed" != *" $svc "* && " ${restart[*]-} " != *" $svc "* ]]; then
    restart+=("$svc")
  fi
done <<<"$itemized"

[[ "$files_changed" -eq 0 ]] && echo "  none differ"

if [[ "$pending" -eq 0 ]]; then
  log "The VM already matches $REF."
  exit 0
fi

if [[ "$mode" == diff ]]; then
  log "This was a diff; the VM is unchanged. Roll it out with: just vm-apply"
  exit 0
fi

if [[ ${#restart[@]} -gt 0 ]]; then
  warn "Config changed for: ${restart[*]} (restarted after the rollout)"
fi
read -r -p "Apply this to $VM_HOST? [y/N] " answer || answer=""
[[ "$answer" == [yY] ]] || die "aborted, nothing changed"

log "Validating the compose file"
# shellcheck disable=SC2029  # REMOTE_DIR is meant to expand locally
ssh "$VM_HOST" "cd $REMOTE_DIR && docker compose -f - --env-file .env config --quiet" \
  <"$src/docker-compose.yaml" || die "the compose file on $REF is invalid; nothing changed"

log "Syncing files"
(cd "$src" && rsync -rc --delete "${SYNC[@]}" "$VM_HOST:$REMOTE_DIR/")

log "Pulling images"
vm "docker compose pull --quiet"

log "Recreating changed services"
vm "docker compose up -d --wait --wait-timeout 180 --remove-orphans" ||
  die "a service did not come up. Old images are kept.
    Logs:      ssh $VM_HOST 'cd $REMOTE_DIR && docker compose logs --tail 50 <service>'
    Roll back: REF=<previous commit> $0 apply"
for svc in ${restart[@]+"${restart[@]}"}; do
  log "Restarting $svc for its new config"
  vm "docker compose restart $svc"
done

log "Checking the versions the services report"
failed=0
while read -r svc img; do
  ref="${img%%@*}"
  expected="${ref##*:}"
  got=""
  for _ in $(seq 1 18); do
    rc=0
    got="$(live_version "$svc" 2>/dev/null)" || rc=$?
    [[ "$rc" -eq 2 || -n "$got" ]] && break
    sleep 5
  done
  if [[ "$rc" -eq 2 ]]; then
    printf '  %-11s not probed\n' "$svc"
  elif [[ "${got#v}" == "${expected#v}" ]]; then
    printf '  %-11s %s ok\n' "$svc" "$got"
  else
    printf '  %-11s %s, expected %s\n' "$svc" "${got:-no answer after 90 s}" "$expected"
    failed=1
  fi
done <<<"$want"

if [[ "$failed" -ne 0 ]]; then
  die "a service is not answering with the expected version. Old images are kept.
    Logs:      ssh $VM_HOST 'cd $REMOTE_DIR && docker compose logs --tail 50 <service>'
    Roll back: REF=<previous commit> $0 apply"
fi

log "Removing images the rollout replaced"
while read -r svc img; do
  ref="${img%%@*}"
  vm "docker image ls '${ref%:*}' --format '{{.Repository}}:{{.Tag}}' | grep -vxF '$ref' |
    xargs -r docker image rm 2>/dev/null | grep '^Untagged' || true"
done <<<"$want"

log "Done."

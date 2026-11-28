# home-ops justfile
# Run `just --list` to see all available commands.

# ─── Settings ────────────────────────────────────────────────────────────────
set positional-arguments := true

# ─── Default ─────────────────────────────────────────────────────────────────
_default:
    @just --list

# ─── Configure / Validate ────────────────────────────────────────────────────

# Encrypt any plaintext secrets and validate manifests
configure:
    #!/usr/bin/env bash
    set -euo pipefail
    for file in $(find kubernetes -type f -name "*.sops.*"); do
        if sops filestatus "$file" | jq --exit-status ".encrypted == false" &>/dev/null; then
            sops --encrypt --in-place "$file"
        fi
    done
    yayamlls validate kubernetes/

# Validate Kubernetes manifests with yayamlls (source + rendered Flux output)
validate:
    yayamlls validate kubernetes/

# Test Flux resources render successfully with flate
flate-test:
    flate test all --path kubernetes/flux

# ─── Git ─────────────────────────────────────────────────────────────────────

# Start BRANCH from origin/main in its own worktree at ../home-ops-<branch>
worktree BRANCH:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="../home-ops-{{ replace(BRANCH, "/", "-") }}"
    git fetch --quiet origin main
    # --no-track keeps origin/main from becoming the upstream, so a bare
    # `git push` can never target main.
    git worktree add --no-track -b "{{ BRANCH }}" "$dir" origin/main
    mise trust --quiet "$dir/mise.toml"
    # Install what this checkout pins, so a merged tool bump is ready before the
    # first command. Best-effort: the worktree already exists at this point.
    mise -C "$dir" install --quiet || echo "warning: mise install failed; run 'just tools' in $dir" >&2
    echo "Worktree ready: cd $dir"

# Remove worktrees and local branches whose PR has merged (dry run; --yes deletes)
worktree-clean *FLAGS:
    #!/usr/bin/env bash
    set -euo pipefail
    apply=false
    for arg in "$@"; do
        case "$arg" in
            --yes) apply=true ;;
            *) echo "unknown argument: $arg (only --yes is accepted)" >&2; exit 2 ;;
        esac
    done
    root="$(cd "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")" && pwd -P)"
    here="$(cd "{{ justfile_directory() }}" && pwd -P)"
    cd "$root"
    git fetch --quiet --prune origin
    if $apply; then git worktree prune; fi
    prs="$(mktemp)"
    trap 'rm -f "$prs"' EXIT
    echo "Fetching PR list from GitHub..."
    gh pr list --state all --limit 100000 --json headRefName,number,state,headRefOid \
        --jq '.[] | [.headRefName, .number, .state, .headRefOid] | @tsv' > "$prs"
    n_wt=0 n_br=0 kb=0 n_kept=0
    while read -r branch <&3; do
        [[ "$branch" == main ]] && continue
        tip="$(git rev-parse "refs/heads/$branch")"
        wt="$(git worktree list --porcelain | awk -v ref="branch refs/heads/$branch" \
            '/^worktree /{p=substr($0,10)} $0==ref{print p}')"
        reason="" merged="" real=""
        if [[ -n "$wt" && -d "$wt" ]]; then real="$(cd "$wt" && pwd -P)"; fi
        if [[ "$real" == "$root" ]]; then
            reason="checked out in the main checkout"
        elif [[ "$real" == "$here" ]]; then
            reason="running from this worktree"
        elif [[ -n "$real" && -n "$(git -C "$wt" status --porcelain)" ]]; then
            reason="uncommitted changes"
        elif [[ -n "$real" ]] \
            && ignored="$(git -C "$wt" ls-files --others --ignored --exclude-standard --directory | sed -n 1p)" \
            && [[ -n "$ignored" ]]; then
            reason="gitignored files ($ignored)"
        else
            # Safe only if every local commit reached a merged PR: the tip is that PR's head or an ancestor of it.
            while IFS=$'\t' read -r _ num state oid; do
                [[ "$state" == MERGED ]] || continue
                if [[ "$oid" == "$tip" ]]; then merged="$num"; break; fi
                git cat-file -e "$oid^{commit}" 2>/dev/null || git fetch --quiet origin "refs/pull/$num/head" 2>/dev/null \
                    || { reason="could not fetch head of merged PR #$num"; continue; }
                if git merge-base --is-ancestor "$tip" "$oid" 2>/dev/null; then merged="$num"; break; fi
                reason="commits after merged PR #$num"
            done < <(awk -F'\t' -v b="$branch" '$1==b' "$prs")
            if [[ -z "$merged" && -z "$reason" ]]; then
                reason="$(awk -F'\t' -v b="$branch" '$1==b{print "PR #" $2 " " tolower($3); exit}' "$prs")"
                if [[ -z "$reason" ]]; then
                    if git show-ref --quiet "refs/remotes/origin/$branch"; then reason="pushed, no PR"; else reason="never pushed"; fi
                fi
            fi
        fi
        if [[ -z "$merged" ]]; then
            n_kept=$((n_kept + 1))
            printf 'keep    %-40s %s%s\n' "$branch" "$reason" "${wt:+  [worktree ${wt}]}"
            continue
        fi
        size=0
        if [[ -n "$wt" && -d "$wt" ]]; then size="$(du -sk "$wt" | cut -f1)"; fi
        if $apply; then
            if [[ -n "$wt" ]] && ! git worktree remove "$wt"; then
                printf 'skip    %-40s git refused to remove %s\n' "$branch" "$wt"
                continue
            fi
            git branch --quiet -D "$branch"
        fi
        printf 'remove  %-40s PR #%s merged%s\n' "$branch" "$merged" "${wt:+  [worktree ${wt}]}"
        n_br=$((n_br + 1))
        if [[ -n "$wt" ]]; then n_wt=$((n_wt + 1)); kb=$((kb + size)); fi
    done 3< <(git for-each-ref --format='%(refname:lstrip=2)' refs/heads)
    echo
    if $apply; then
        echo "Removed $n_br branches, $n_wt of them with a worktree ($((kb / 1024)) MB). Kept $n_kept."
    else
        echo "Would remove $n_br branches, $n_wt of them with a worktree ($((kb / 1024)) MB). Would keep $n_kept."
        echo "Run 'just worktree-clean --yes' to delete them."
    fi

# ─── Bootstrap ───────────────────────────────────────────────────────────────

# Bootstrap the Talos cluster (not re-tested since the move to topf, see #4262)
bootstrap-talos:
    #!/usr/bin/env bash
    set -euo pipefail
    cd talos
    # Generates and sops-encrypts secrets.sops.yaml only if it does not exist.
    topf secrets --confirm=false > /dev/null
    topf apply --auto-bootstrap --confirm=false
    topf talosconfig > clusterconfig/talosconfig
    # topf issues 12h admin certs by default.
    topf kubeconfig --validity 8760h > ../kubeconfig

# Bootstrap apps into the Talos cluster
bootstrap-apps:
    bash scripts/bootstrap-apps.sh

# Bootstrap Rook-Ceph [MODEL=250GB]
bootstrap-rook MODEL="250GB":
    #!/usr/bin/env bash
    set -euo pipefail
    export MODEL="{{MODEL}}"
    export NODE_COUNT=$(talosctl config info --output json | jq --raw-output '.nodes | length')
    minijinja-cli .taskfiles/bootstrap/resources/wipe-rook.yaml.j2 | kubectl apply --server-side --filename -
    until kubectl --namespace default get job/wipe-rook &>/dev/null; do sleep 5; done
    kubectl --namespace default wait job/wipe-rook --for=condition=complete --timeout=5m
    stern --namespace default job/wipe-rook --no-follow
    kubectl --namespace default delete job wipe-rook

# Bootstrap the SOPS Age key
bootstrap-age-key:
    age-keygen --output age.key

# ─── Kubernetes ──────────────────────────────────────────────────────────────

# Apply a Flux KS [PATH=required]
apply-ks PATH:
    #!/usr/bin/env bash
    set -euo pipefail
    KS=$(basename "{{PATH}}")
    if flux --namespace flux-system get kustomizations "$KS" 2>&1 | grep -q "not found"; then
        DRY_RUN="--dry-run"
    else
        DRY_RUN=""
    fi
    flux build --namespace flux-system ks "$KS" \
        --kustomization-file kubernetes/apps/{{PATH}}/ks.yaml \
        --path kubernetes/apps/{{PATH}} $DRY_RUN \
    | yq 'with(select(.apiVersion == "kustomize.toolkit.fluxcd.io/v1" and .kind == "Kustomization"); .metadata.namespace = "flux-system")' - \
    | kubectl apply --server-side --field-manager=kustomize-controller --filename -

# Force Flux to reconcile
reconcile:
    flux --namespace flux-system reconcile kustomization cluster --with-source

# Force Flux to pull in changes from Git repo
reconcile-flux:
    flux reconcile -n flux-system source git flux-system
    flux reconcile -n flux-system kustomization cluster

# Restart all failed Helm Releases
hr-restart:
    #!/usr/bin/env bash
    set -euo pipefail
    kubectl get hr --all-namespaces | grep False | awk '{print $2, $1}' | xargs -L 2 bash -c 'flux suspend hr $0 -n $1'
    kubectl get hr --all-namespaces | grep False | awk '{print $2, $1}' | xargs -L 2 bash -c 'flux resume hr $0 -n $1'

# Verify Flux prerequisites
flux-check:
    flux check --pre

# Install Flux into your cluster
flux-install:
    #!/usr/bin/env bash
    set -euo pipefail
    PROMETHEUS_OP_VERSION=v0.72.0
    kubectl apply --server-side --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$PROMETHEUS_OP_VERSION/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
    kubectl apply --server-side --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$PROMETHEUS_OP_VERSION/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
    kubectl apply --server-side --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$PROMETHEUS_OP_VERSION/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml
    kubectl apply --server-side --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$PROMETHEUS_OP_VERSION/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
    kubectl apply --kustomize kubernetes/bootstrap
    cat age.key | kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=/dev/stdin
    sops --decrypt kubernetes/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
    kubectl apply -f kubernetes/flux/vars/cluster-settings.yaml
    kubectl apply --kustomize kubernetes/flux/config

# ─── Cluster Resources ───────────────────────────────────────────────────────

# List nodes [ARGS=-o wide]
nodes *ARGS="-o wide":
    kubectl get nodes {{ARGS}}

# List all pods [ARGS=-A]
pods *ARGS="-A":
    kubectl get pods {{ARGS}}

# List all kustomizations [ARGS=-A]
kustomizations *ARGS="-A":
    kubectl get kustomizations {{ARGS}}

# List all helmreleases [ARGS=-A]
helmreleases *ARGS="-A":
    kubectl get helmreleases {{ARGS}}

# List all helmrepositories [ARGS=-A]
helmrepositories *ARGS="-A":
    kubectl get helmrepositories {{ARGS}}

# List all gitrepositories [ARGS=-A]
gitrepositories *ARGS="-A":
    kubectl get gitrepositories {{ARGS}}

# List all certificates [ARGS=-A]
certificates *ARGS="-A":
    kubectl get certificates {{ARGS}}
    kubectl get certificaterequests {{ARGS}}

# List all ingresses [ARGS=-A]
ingresses *ARGS="-A":
    kubectl get ingress {{ARGS}}

# Gather all common resources (support bundle)
resources:
    @just nodes
    @just kustomizations
    @just helmreleases
    @just helmrepositories
    @just gitrepositories
    @just certificates
    @just ingresses
    @just pods

# ─── Talos ───────────────────────────────────────────────────────────────────

# Show what applying talos/ would change on each node, without applying
talos-diff:
    cd talos && { topf apply --dry-run || [ $? -eq 2 ]; }

# Apply Talos config to a node; shows the diff and asks first [NODE=required, e.g. k8s-1] [MODE=auto]
talos-apply NODE MODE="auto":
    cd talos && topf apply --nodes-filter '^{{NODE}}$' --mode '{{MODE}}'

# Render machine configs to talos/output (they contain secrets; gitignored)
talos-render:
    cd talos && topf render

# Upgrade Talos on a node to talosVersion in topf.yaml; asks first [NODE=required]
talos-upgrade NODE:
    # powercycle, as in the tuppr TalosUpgrade: a kexec reboot leaves the Arc GPU on k8s-0 wedged.
    cd talos && topf upgrade --nodes-filter '^{{NODE}}$' --reboot-mode powercycle

# Upgrade Kubernetes to kubernetesVersion in topf.yaml (topf does not manage this)
talos-upgrade-k8s:
    #!/usr/bin/env bash
    set -euo pipefail
    cd talos
    talosctl --nodes "$(yq '[.nodes[] | select(.role == "control-plane")][0].ip' topf.yaml)" \
        upgrade-k8s --to "$(yq '.kubernetesVersion' topf.yaml)"

# Reset nodes back to maintenance mode (DESTRUCTIVE; asks first)
talos-reset:
    cd talos && topf reset

# ─── Plex ────────────────────────────────────────────────────────────────────

# Get the Plex pod name
plex-pod:
    kubectl get pod -n media -l app.kubernetes.io/name=plex -o jsonpath='{.items[0].metadata.name}'

# Show Plex container logs [ARGS=-f]
plex-logs *ARGS="-f":
    kubectl logs -n media -l app.kubernetes.io/name=plex {{ARGS}}

# List all Plex log files
plex-logs-list:
    kubectl exec -n media $(just plex-pod) -- ls -lah "/config/Library/Application Support/Plex Media Server/Logs"

# View main Plex Media Server log
plex-logs-main:
    kubectl exec -n media $(just plex-pod) -- cat "/config/Library/Application Support/Plex Media Server/Logs/Plex Media Server.log"

# Tail Plex logs in real-time
plex-logs-tail:
    kubectl exec -n media $(just plex-pod) -- tail -f "/config/Library/Application Support/Plex Media Server/Logs/Plex Media Server.log"

# View last N lines of Plex log [LINES=100]
plex-logs-last LINES="100":
    kubectl exec -n media $(just plex-pod) -- tail -n {{LINES}} "/config/Library/Application Support/Plex Media Server/Logs/Plex Media Server.log"

# Search Plex logs [PATTERN=required]
plex-grep PATTERN:
    kubectl exec -n media $(just plex-pod) -- grep -i "{{PATTERN}}" "/config/Library/Application Support/Plex Media Server/Logs/Plex Media Server.log"

# Search for errors in Plex log
plex-errors:
    kubectl exec -n media $(just plex-pod) -- grep -i error "/config/Library/Application Support/Plex Media Server/Logs/Plex Media Server.log"

# Search for warnings in Plex log
plex-warnings:
    kubectl exec -n media $(just plex-pod) -- grep -i warn "/config/Library/Application Support/Plex Media Server/Logs/Plex Media Server.log"

# Copy all Plex logs [DEST=./plex-logs]
plex-logs-copy DEST="./plex-logs":
    kubectl cp media/$(just plex-pod):"/config/Library/Application Support/Plex Media Server/Logs" {{DEST}}

# Copy main Plex log [DEST=./plex-server.log]
plex-logs-copy-main DEST="./plex-server.log":
    kubectl cp media/$(just plex-pod):"/config/Library/Application Support/Plex Media Server/Logs/Plex Media Server.log" {{DEST}}

# Execute command in Plex container [CMD=required]
plex-exec CMD:
    kubectl exec -n media -it $(just plex-pod) -- {{CMD}}

# Open a shell in Plex container
plex-shell:
    kubectl exec -n media -it $(just plex-pod) -- /bin/bash

# Describe Plex pod
plex-describe:
    kubectl describe pod -n media -l app.kubernetes.io/name=plex

# Restart Plex pod
plex-restart:
    kubectl delete pod -n media -l app.kubernetes.io/name=plex

# ─── VolSync ─────────────────────────────────────────────────────────────────

# Suspend VolSync
volsync-suspend:
    flux --namespace flux-system suspend kustomization volsync
    flux --namespace volsync-system suspend helmrelease volsync
    kubectl --namespace volsync-system scale deployment volsync --replicas 0

# Resume VolSync
volsync-resume:
    flux --namespace flux-system resume kustomization volsync
    flux --namespace volsync-system resume helmrelease volsync
    kubectl --namespace volsync-system scale deployment volsync --replicas 1

# Unlock all Kopia source repos
volsync-unlock:
    #!/usr/bin/env bash
    set -euo pipefail
    kubectl get replicationsources --all-namespaces --no-headers --output=jsonpath='{range .items[*]}{.metadata.namespace},{.metadata.name}{"\n"}{end}' | while IFS=, read -r ns name; do
        kubectl --namespace "$ns" patch --field-manager=flux-client-side-apply replicationsources "$name" --type merge --patch "{\"spec\":{\"kopia\":{\"unlock\":\"$(date +%s)\"}}}"
    done

# Snapshot an app [APP=required] [NS=default]
volsync-snapshot APP NS="default":
    #!/usr/bin/env bash
    set -euo pipefail
    kubectl --namespace {{NS}} patch replicationsources {{APP}} --type merge -p '{"spec":{"trigger":{"manual":"'$(date +%s)'"}}}'
    until kubectl --namespace {{NS}} get job/volsync-src-{{APP}} &>/dev/null; do sleep 5; done
    kubectl --namespace {{NS}} wait job/volsync-src-{{APP}} --for=condition=complete --timeout=120m

# Restore an app from latest snapshot [APP=required] [NS=default]
volsync-restore APP NS="default":
    #!/usr/bin/env bash
    set -euo pipefail
    NS="{{NS}}"
    APP="{{APP}}"
    flux --namespace "$NS" suspend kustomization "$APP"
    CONTROLLER=$(kubectl --namespace "$NS" get deployment "$APP" &>/dev/null && echo deployment || echo statefulset)
    kubectl --namespace "$NS" scale "$CONTROLLER/$APP" --replicas 0
    kubectl --namespace "$NS" wait pod --for=delete --selector="app.kubernetes.io/name=$APP" --timeout=5m
    kubectl --namespace "$NS" delete pvc "$APP" --ignore-not-found
    kubectl --namespace "$NS" patch replicationdestination "$APP-dst" --type merge -p '{"spec":{"trigger":{"manual":"'$(date +%s)'"}}}'
    until kubectl --namespace "$NS" get job/volsync-dst-"$APP"-dst &>/dev/null; do sleep 5; done
    kubectl --namespace "$NS" wait job/volsync-dst-"$APP"-dst --for=condition=complete --timeout=120m
    flux --namespace "$NS" resume kustomization "$APP"
    flux --namespace "$NS" reconcile kustomization "$APP" --with-source
    flux --namespace "$NS" reconcile helmrelease "$APP" --force
    until kubectl --namespace "$NS" get pod --selector="app.kubernetes.io/name=$APP" -o name | grep -q pod; do sleep 5; done
    kubectl --namespace "$NS" wait pod --for=condition=ready --selector="app.kubernetes.io/name=$APP" --timeout=5m

# Unlock a Kopia source repo locally [APP=required] [NS=default]
volsync-unlock-local APP NS="default":
    #!/usr/bin/env bash
    set -euo pipefail
    export NS="{{NS}}"
    export APP="{{APP}}"
    minijinja-cli --env .taskfiles/volsync/resources/unlock.yaml.j2 | kubectl apply --server-side --filename -
    until kubectl --namespace "$NS" get job/volsync-unlock-"$APP" &>/dev/null; do sleep 5; done
    kubectl --namespace "$NS" wait job/volsync-unlock-"$APP" --for condition=complete --timeout=5m
    stern --namespace "$NS" job/volsync-unlock-"$APP" --no-follow
    kubectl --namespace "$NS" delete job volsync-unlock-"$APP"

# ─── Observability VM ────────────────────────────────────────────────────────

# Show how the observability VM differs from vm/observability on main
vm-diff:
    scripts/vm-observability.sh

# Roll the observability VM to main: sync config, pull, recreate, check versions
vm-apply:
    scripts/vm-observability.sh apply

# ─── Workstation ─────────────────────────────────────────────────────────────

# Install the pinned toolchain from mise.toml
tools:
    mise install

# ─── Pre-commit ──────────────────────────────────────────────────────────────

# Install pre-commit hooks
precommit-init:
    pre-commit install-hooks

# Run pre-commit on all files
precommit:
    pre-commit run --all-files

# Update pre-commit hooks
precommit-update:
    pre-commit autoupdate

# ─── Cleanup ─────────────────────────────────────────────────────────────────

# Clean files after cluster bootstrap
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p .private
    rm -rf .github/tests .github/workflows/e2e.yaml .devcontainer/ci .github/workflows/devcontainer.yaml
    mv bootstrap .private/bootstrap-$(date +%s)
    mv makejinja.toml .private/makejinja-$(date +%s).toml 2>/dev/null || true
    sed -i '' 's/(..\.j2)?//g' .github/renovate.json5

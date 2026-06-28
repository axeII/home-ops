# home-ops justfile
# Run `just --list` to see all available commands.

# ─── Settings ────────────────────────────────────────────────────────────────
set positional-arguments := true

# ─── Default ─────────────────────────────────────────────────────────────────
_default:
    @just --list

# ─── Configure / Validate ────────────────────────────────────────────────────

# Render templates, check secrets, and validate manifests
configure:
    #!/usr/bin/env bash
    set -euo pipefail
    .venv/bin/makejinja
    for file in $(find kubernetes -type f -name "*.sops.*"); do
        if sops filestatus "$file" | jq --exit-status ".encrypted == false" &>/dev/null; then
            sops --encrypt --in-place "$file"
        fi
    done
    bash .taskfiles/scripts/kubeconform.sh kubernetes

# Validate Kubernetes manifests with kubeconform
kubeconform:
    bash .taskfiles/scripts/kubeconform.sh kubernetes

# ─── Bootstrap ───────────────────────────────────────────────────────────────

# Bootstrap the Talos cluster
bootstrap-talos:
    #!/usr/bin/env bash
    set -euo pipefail
    cd talos
    [ -f talsecret.sops.yaml ] || talhelper gensecret | sops --filename-override talos/talsecret.sops.yaml --encrypt /dev/stdin > talsecret.sops.yaml
    talhelper genconfig
    talhelper gencommand apply --extra-flags="--insecure" | bash
    until talhelper gencommand bootstrap | bash; do sleep 10; done
    until talhelper gencommand kubeconfig --extra-flags="$(pwd)/.. --force" | bash; do sleep 10; done

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

# Generate Talos node configuration
talos-genconfig:
    cd talos && talhelper genconfig

# Apply Talos config to a node [IP=required] [MODE=auto]
talos-apply IP MODE="auto":
    cd talos && talhelper gencommand apply --node {{IP}} --extra-flags '--mode={{MODE}}' | bash

# Upgrade Talos on a node [IP=required]
talos-upgrade IP:
    #!/usr/bin/env bash
    set -euo pipefail
    cd talos
    TALOS_IMAGE=$(yq '.nodes[] | select(.ipAddress == "{{IP}}") | .talosImageURL' talconfig.yaml)
    TALOS_VERSION=$(yq '.talosVersion' talenv.yaml)
    talhelper gencommand upgrade --node {{IP}} --extra-flags "--image='$TALOS_IMAGE:$TALOS_VERSION' --timeout=10m" | bash

# Upgrade Kubernetes
talos-upgrade-k8s:
    #!/usr/bin/env bash
    set -euo pipefail
    cd talos
    KUBE_VERSION=$(yq '.kubernetesVersion' talenv.yaml)
    talhelper gencommand upgrade-k8s --extra-flags "--to '$KUBE_VERSION'" | bash

# Reset nodes back to maintenance mode
talos-reset:
    cd talos && talhelper gencommand reset --extra-flags="--reboot --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL --graceful=false --wait=false" | bash

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

# ─── Workstation ─────────────────────────────────────────────────────────────

# Install Homebrew tools
brew:
    brew bundle --file .taskfiles/workstation/Brewfile

# Allow direnv
direnv:
    direnv allow .

# Set up Python virtual environment
venv:
    python3 -m venv .venv
    .venv/bin/python3 -m pip install --upgrade pip setuptools wheel
    .venv/bin/python3 -m pip install --upgrade --requirement requirements.txt

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

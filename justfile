# home-ops tasks. Run `just` to list them by group.
#
# The tools these recipes call are pinned in mise.toml, which CI reads too.
# After pulling a bump to it, `just tools` installs the new versions.

set positional-arguments

_default:
    @just --list --unsorted

# ─── Validate: run before every commit ───────────────────────────────────────

# Encrypt any plaintext *.sops.* file under kubernetes/, then validate
[group('validate')]
configure: && validate
    #!/usr/bin/env bash
    set -euo pipefail
    for file in $(find kubernetes -type f -name "*.sops.*"); do
        if sops filestatus "$file" | jq --exit-status ".encrypted == false" &>/dev/null; then
            sops --encrypt --in-place "$file"
        fi
    done

# Validate manifests with yayamlls, both source and rendered Flux output
[group('validate')]
validate:
    yayamlls validate kubernetes/

# Check that every Flux resource renders, with flate
[group('validate')]
flate-test:
    flate test all --path kubernetes/flux

# ─── Workstation ─────────────────────────────────────────────────────────────

# Install the tool versions mise.toml pins
[group('workstation')]
tools:
    mise install

# Start BRANCH from origin/main in its own worktree at ../home-ops-<branch>
[group('workstation')]
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

# Remove worktrees and branches whose PR has merged (dry run; --yes deletes)
[group('workstation')]
worktree-clean *FLAGS:
    scripts/worktree-clean.sh "$@"

# Run pre-commit on all files
[group('workstation')]
precommit:
    pre-commit run --all-files

# Build the pre-commit hook environments
[group('workstation')]
precommit-init:
    pre-commit install-hooks

# Bump the hook versions in .pre-commit-config.yaml
[group('workstation')]
precommit-update:
    pre-commit autoupdate

# ─── Flux ────────────────────────────────────────────────────────────────────

# Fetch Git and apply cluster-meta and cluster-apps now instead of waiting for their interval
[group('flux')]
reconcile:
    flux --namespace flux-system reconcile kustomization cluster-meta --with-source
    flux --namespace flux-system reconcile kustomization cluster-apps

# Apply an app from the working tree, bypassing Git (APP is its folder, e.g. default/atuin)
[group('flux')]
apply-ks APP KS="":
    #!/usr/bin/env bash
    set -euo pipefail
    file="kubernetes/apps/$1/ks.yaml"
    names="$(yq -N 'select(.kind == "Kustomization") | .metadata.name' "$file")"
    ks="${2:-}"
    if [[ -z "$names" ]]; then
        echo "no Kustomization in $file" >&2
        exit 1
    elif [[ -z "$ks" && "$(grep -c . <<<"$names")" -eq 1 ]]; then
        ks="$names"
    elif [[ -z "$ks" ]] || ! grep -qxF -- "$ks" <<<"$names"; then
        echo "name the Kustomization: just apply-ks $1 <$(paste -sd '|' - <<<"$names")>" >&2
        exit 1
    fi
    path="$(ks="$ks" yq -N 'select(.kind == "Kustomization" and .metadata.name == strenv(ks)) | .spec.path' "$file")"
    # kubernetes/apps/<namespace>/kustomization.yaml overrides the namespace in
    # ks.yaml (external-dns says flux-system but runs in network). flux build
    # matches the file by namespace too, so give it the effective one.
    ns="${1%%/*}"
    ks_file="$(mktemp)"
    trap 'rm -f "$ks_file"' EXIT
    ns="$ns" yq '(select(.kind == "Kustomization") | .metadata.namespace) = strenv(ns)' "$file" >"$ks_file"
    # flux build takes the substitutions from the live Kustomization, so it fails
    # for an app Flux has not created yet. Build first, so a failure applies nothing.
    rendered="$(flux build kustomization "$ks" --namespace "$ns" --kustomization-file "$ks_file" --path "$path")"
    kubectl apply --server-side --field-manager=kustomize-controller --filename - <<<"$rendered"

# Suspend and resume every HelmRelease that is not Ready, to retry failed releases
[group('flux')]
hr-restart:
    #!/usr/bin/env bash
    set -euo pipefail
    failing="$(kubectl get helmreleases --all-namespaces --output json \
        | jq -r '.items[] | select(any(.status.conditions[]?; .type == "Ready" and .status == "False"))
            | "\(.metadata.namespace) \(.metadata.name)"')"
    rc=0
    while read -r ns name; do
        [[ -z "$ns" ]] && continue
        flux --namespace "$ns" suspend helmrelease "$name"
        flux --namespace "$ns" resume helmrelease "$name" || { echo "still not Ready: $ns/$name" >&2; rc=1; }
    done <<<"$failing"
    exit "$rc"

# Check that the cluster meets Flux's prerequisites
[group('flux')]
flux-check:
    flux check --pre

# ─── Cluster status ──────────────────────────────────────────────────────────

# List nodes
[group('cluster')]
nodes *ARGS="-o wide":
    kubectl get nodes {{ ARGS }}

# List pods
[group('cluster')]
pods *ARGS="-A":
    kubectl get pods {{ ARGS }}

# List Flux Kustomizations
[group('cluster')]
kustomizations *ARGS="-A":
    kubectl get kustomizations {{ ARGS }}

# List HelmReleases
[group('cluster')]
helmreleases *ARGS="-A":
    kubectl get helmreleases {{ ARGS }}

# List HelmRepositories
[group('cluster')]
helmrepositories *ARGS="-A":
    kubectl get helmrepositories {{ ARGS }}

# List GitRepositories
[group('cluster')]
gitrepositories *ARGS="-A":
    kubectl get gitrepositories {{ ARGS }}

# List certificates and certificate requests
[group('cluster')]
certificates *ARGS="-A":
    kubectl get certificates {{ ARGS }}
    kubectl get certificaterequests {{ ARGS }}

# List ingresses
[group('cluster')]
ingresses *ARGS="-A":
    kubectl get ingress {{ ARGS }}

# Show all of the above in one go, e.g. for a support bundle
[group('cluster')]
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
[group('talos')]
talos-diff:
    cd talos && { topf apply --dry-run || [ $? -eq 2 ]; }

# Apply Talos config to NODE (e.g. k8s-1); shows the diff and asks first
[group('talos')]
talos-apply NODE MODE="auto":
    cd talos && topf apply --nodes-filter '^{{ NODE }}$' --mode '{{ MODE }}'

# Render machine configs to talos/output (they contain secrets; gitignored)
[group('talos')]
talos-render:
    cd talos && topf render

# Reboots with powercycle, as the tuppr TalosUpgrade does: a kexec reboot
# leaves the Arc GPU on k8s-0 wedged.
#
# Upgrade Talos on NODE to talosVersion in topf.yaml; asks first
[group('talos')]
talos-upgrade NODE:
    cd talos && topf upgrade --nodes-filter '^{{ NODE }}$' --reboot-mode powercycle

# Upgrade Kubernetes to kubernetesVersion in topf.yaml (topf does not manage this)
[group('talos')]
talos-upgrade-k8s:
    #!/usr/bin/env bash
    set -euo pipefail
    cd talos
    talosctl --nodes "$(yq '[.nodes[] | select(.role == "control-plane")][0].ip' topf.yaml)" \
        upgrade-k8s --to "$(yq '.kubernetesVersion' topf.yaml)"

# Reset nodes back to maintenance mode (DESTRUCTIVE; asks first)
[group('talos')]
talos-reset:
    cd talos && topf reset

# ─── VolSync ─────────────────────────────────────────────────────────────────

# Back up APP now and wait for the backup to finish
[group('volsync')]
volsync-snapshot APP NS="default":
    #!/usr/bin/env bash
    set -euo pipefail
    kubectl --namespace {{ NS }} patch replicationsources {{ APP }} --type merge -p '{"spec":{"trigger":{"manual":"'$(date +%s)'"}}}'
    until kubectl --namespace {{ NS }} get job/volsync-src-{{ APP }} &>/dev/null; do sleep 5; done
    kubectl --namespace {{ NS }} wait job/volsync-src-{{ APP }} --for=condition=complete --timeout=120m

# Restore APP from its latest backup (DESTRUCTIVE: deletes its PVC first)
[group('volsync')]
volsync-restore APP NS="default":
    #!/usr/bin/env bash
    set -euo pipefail
    NS="{{ NS }}"
    APP="{{ APP }}"
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

# Unlock every Kopia repository, e.g. after an interrupted backup
[group('volsync')]
volsync-unlock:
    #!/usr/bin/env bash
    set -euo pipefail
    kubectl get replicationsources --all-namespaces --no-headers --output=jsonpath='{range .items[*]}{.metadata.namespace},{.metadata.name}{"\n"}{end}' | while IFS=, read -r ns name; do
        kubectl --namespace "$ns" patch --field-manager=flux-client-side-apply replicationsources "$name" --type merge --patch "{\"spec\":{\"kopia\":{\"unlock\":\"$(date +%s)\"}}}"
    done

# Stop VolSync: suspend its Kustomization and HelmRelease, scale it to 0
[group('volsync')]
volsync-suspend:
    flux --namespace volsync-system suspend kustomization volsync
    flux --namespace volsync-system suspend helmrelease volsync
    kubectl --namespace volsync-system scale deployment volsync --replicas 0

# Start VolSync again after volsync-suspend
[group('volsync')]
volsync-resume:
    flux --namespace volsync-system resume kustomization volsync
    flux --namespace volsync-system resume helmrelease volsync
    kubectl --namespace volsync-system scale deployment volsync --replicas 1

# ─── Observability VM ────────────────────────────────────────────────────────

# Show how the observability VM differs from vm/observability on main
[group('vm')]
vm-diff:
    scripts/vm-observability.sh

# Roll the observability VM to main: sync config, pull, recreate, check versions
[group('vm')]
vm-apply:
    scripts/vm-observability.sh apply

# ─── Bootstrap: a new cluster only ───────────────────────────────────────────

# Create the SOPS Age key (age-keygen refuses to overwrite an existing age.key)
[group('bootstrap')]
bootstrap-age-key:
    age-keygen --output age.key

# Bootstrap the Talos cluster (not re-tested since the move to topf, see #4262)
[group('bootstrap')]
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

# Install the bootstrap charts and Flux into the new cluster
[group('bootstrap')]
bootstrap-apps:
    bash scripts/bootstrap-apps.sh

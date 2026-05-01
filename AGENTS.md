# AGENTS.md

Home-ops IaC repo — Kubernetes cluster managed with Flux CD, Talos Linux, and SOPS/Age encryption.

## Project layout

- `kubernetes/apps/` — App manifests organized by namespace (e.g. `observability/`, `media/`, `default/`).
- `kubernetes/flux/` — Flux GitOps config (cluster kustomizations, Helm repos, namespaces).
- `kubernetes/components/` — Shared Kustomize components (common labels, sops, gatus, volsync).
- `talos/` — Talos Linux node config, patches, and secrets.
- `scripts/` — Helper scripts for validation, backups, and DNS.
- `Taskfile.yaml` — All operations go through `task`. Run `task --list` to see available commands.

## Validation

- Run `task configure` to render templates, check secrets, and validate manifests.
- Run `task kubernetes:kubeconform` to validate Kubernetes manifests with kubeconform.
- Run `python3 scripts/find_mistakes.py` to check for broken Kustomize references (needs `fd`).
- Run `pre-commit run --all-files` to lint YAML, fix whitespace, and scan for leaked secrets.
- Fix all errors before committing. The commit should pass all checks.

## Talos changes

- Run `task talos:generate-config` to regenerate node configs after editing `talos/patches/`.
- Apply to each control plane node: `task talos:apply-node IP=192.168.69.110` (repeat for .111, .112).
- Static pod resources (apiserver, etcd, etc.) live in `talos/patches/controller/`. Always set both `requests` and `limits`.
- Check for OOM issues: `talosctl -n <node-ip> dmesg | grep -i "oom\|kill"`.

## Secrets

- NEVER commit unencrypted secrets. All secrets use SOPS with Age encryption.
- Secret files are named `*.sops.yaml`. The `age.key` must never be committed.
- Ask the user to handle encryption, or use `task bootstrap:secrets`.

## Useful commands

- `task reconcile` — Force Flux to reconcile the cluster.
- `kubectl get pods -n <namespace>` — Check pod status.
- `kubectl top nodes` — Check resource usage.

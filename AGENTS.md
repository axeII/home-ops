# AGENTS.md

Home-ops IaC repo — Kubernetes cluster managed with Flux CD, Talos Linux, and SOPS/Age encryption.

## Project layout

- `kubernetes/apps/` — App manifests organized by namespace (e.g. `observability/`, `media/`, `default/`).
- `kubernetes/flux/` — Flux GitOps config (cluster kustomizations, Helm repos, namespaces).
- `kubernetes/components/` — Shared Kustomize components (common labels, sops, gatus, volsync).
- `talos/` — Talos Linux node config, patches, and secrets.
- `scripts/` — Helper scripts for validation, backups, and DNS.
- `justfile` — All operations go through `just`. Run `just --list` to see available commands.

## Validation

- Run `just configure` to render templates, check secrets, and validate manifests.
- Run `just kubeconform` to validate Kubernetes manifests with kubeconform.
- Run `python3 scripts/find_mistakes.py` to check for broken Kustomize references (needs `fd`).
- Run `pre-commit run --all-files` to lint YAML, fix whitespace, and scan for leaked secrets.
- Fix all errors before committing. The commit should pass all checks.
- Add always new line at the end of files

## Talos changes

- Run `just talos-genconfig` to regenerate node configs after editing `talos/patches/`.
- Apply to each control plane node: `just talos-apply IP=192.168.69.110` (repeat for .111, .112).
- Static pod resources (apiserver, etcd, etc.) live in `talos/patches/controller/`. Always set both `requests` and `limits`.
- Check for OOM issues: `talosctl -n <node-ip> dmesg | grep -i "oom\|kill"`.

## Secrets

- NEVER commit unencrypted secrets. All secrets use SOPS with Age encryption.
- Secret files are named `*.sops.yaml`. The `age.key` must never be committed.
- Ask the user to handle encryption, or use `just configure` to auto-encrypt.

## Useful commands

- `just reconcile` — Force Flux to reconcile the cluster.
- `kubectl get pods -n <namespace>` — Check pod status.
- `kubectl top nodes` — Check resource usage.

## Observability

- Metrics and logs are shipped to **Grafana Cloud** via Alloy (in `observability` namespace).
- `kubernetes/apps/observability/grafana-cloud/` — Alloy deployment with River config.
- `kubernetes/apps/observability/kromgo/` — README badges, queries Grafana Cloud Prometheus API.
- `kubernetes/apps/observability/gatus/` — HTTP health checks, independent of metrics backend.
- Exporters (node-exporter, kube-state-metrics, etc.) still run locally, scraped by Alloy.
- To set up Grafana Cloud: create account at grafana.com, create a stack, store credentials in 1Password as `grafana-cloud` item with keys: `GRAFANA_CLOUD_PROMETHEUS_URL`, `GRAFANA_CLOUD_PROMETHEUS_USER`, `GRAFANA_CLOUD_LOKI_URL`, `GRAFANA_CLOUD_LOKI_USER`, `GRAFANA_CLOUD_API_TOKEN`.

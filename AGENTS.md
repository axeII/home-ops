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
- Run `just validate` to validate YAML schemas on source files via yayamlls.
- Run `just flate-test` to verify all Flux resources render successfully with flate.
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

## CI tools

- **flate** — Offline Flux renderer. `flate test all --path kubernetes/flux` validates all resources render. Used in CI as a synchronous merge gate.
- **yayamlls** — YAML language server with Kubernetes schema validation. `yayamlls validate --render kubernetes/` validates source + rendered Flux output. Also provides editor LSP support via `.yayamlls.yaml`.
- **konflate** — PR review service deployed in the `flux-system` namespace. Renders PRs with flate, surfaces blast radius, image changes, and danger flags. Posts status checks and summary comments. Web UI at `konflate.juno.moe`.

## Auto-merge policy

The `.github/workflows/auto-merge.yaml` workflow runs daily at 02:00 UTC and applies these rules:

| Category | Detection | Min age | Days | Konflate gate |
|---|---|---|---|---|
| **patch / digest** | `type/patch`, `type/digest` | **2d** | any | no failures, no cautions |
| **minor** (release train) | `type/minor` | **3d** | **Fri–Sat** (Europe/Berlin) | no failures, no cautions |
| **major (ci/gh-action)** | `type/major` + `renovate/github-action` | **2d** | any | no failures (cautions allowed) |
| **major (other)** | `type/major`, not `renovate/github-action` | — | MANUAL | — |
| **rook-ceph** | title/branch matches `rook-ceph` | — | MANUAL | — |
| **area/talos** | `area/talos` label (`talos/**`) | — | MANUAL | — |

- **Cluster quiet window:** Sun 00:00–05:00 UTC — no merges (Talos upgrade window).
- **Sleep between merges:** 300 seconds to let Flux reconcile before the next merge.
- Konflate re-render is triggered before each merge gate via `KONFLATE_PUSH_TOKEN`.
- **Bulk merge** (`.github/workflows/bulk-merge-prs.yaml`) also excludes rook-ceph, `area/talos`, `type/major`, `type/minor`, and `hold`.
- **Konflate** is reachable only from inside the home network (private IP). From GitHub Actions, the konflate gate is skipped — the auto-merge relies on label/age/day rules alone. `Konflate` as a required status check in branch protection won't work from outside the network.
- **Konflate write-back** posts a summary PR comment + commit status after each render when reachable (inside the network).
- **Setup:** add `KONFLATE_PUSH_TOKEN` (random 32-byte hex) to 1Password `konflate` item and as a GitHub Actions secret; confirm the GitHub App has `checks: write` + `pull-requests: write` permissions.

## Cloudflare WAF rules

Required WAF rules for the `juno.moe` zone (effective only when DNS records are Proxied/orange-cloud — required for `external.juno.moe` to route through the Cloudflare Tunnel):

| # | Rule name | Priority | Expression | Action |
|---|---|---|---|---|
| 1 | Block threats | 0 | `(cf.threat_score gt 40)` | Block |
| 2 | Allow github webhooks | 20 | `(http.request.uri.path contains "/hook") and (ip.src in {192.30.252.0/22, 185.199.108.0/22, 140.82.112.0/20, 143.55.64.0/20})` | Skip |
| 3 | Block bots | 10 | `(cf.client.bot)` | Block |
| 4 | Allow kromgo and konflate | 45 | `((http.host wildcard "kromgo.juno.moe*") or (http.host eq "konflate.juno.moe")) and (ip.geoip.country eq "US")` | Skip |
| 5 | Allow only home country | 5 | `(ip.geoip.country ne "CZ")` | Block |

- **Rule 2** replaces the previous broad `/hook OR /api/` rule — `/api/` is no longer opened to everyone; GitHub Actions reaches konflate `/api/` via Rule 4 (host + US country).
- **Rule 3** uses Cloudflare's `cf.client.bot` field (verified bots flag) — more reliable than the previous `Known Bots equals true`.
- **GitHub webhook IPs** are published at `https://api.github.com/meta` under `hooks`. Update Rule 2's IP list when GitHub announces new ranges.

## Observability

- Metrics and logs are shipped to **Grafana Cloud** via Alloy (in `observability` namespace).
- `kubernetes/apps/observability/grafana-cloud/` — Alloy deployment with River config.
- `kubernetes/apps/observability/kromgo/` — README badges, queries Grafana Cloud Prometheus API.
- `kubernetes/apps/observability/gatus/` — HTTP health checks, independent of metrics backend.
- Exporters (node-exporter, kube-state-metrics, etc.) still run locally, scraped by Alloy.
- To set up Grafana Cloud: create account at grafana.com, create a stack, store credentials in 1Password as `grafana-cloud` item with keys: `GRAFANA_CLOUD_PROMETHEUS_URL`, `GRAFANA_CLOUD_PROMETHEUS_USER`, `GRAFANA_CLOUD_LOKI_URL`, `GRAFANA_CLOUD_LOKI_USER`, `GRAFANA_CLOUD_API_TOKEN`.

# AGENTS.md

Home-ops IaC repo — Kubernetes cluster managed with Flux CD, Talos Linux, and SOPS/Age encryption.

## Project model

opencode/AI works as the **medior developer** — it implements changes, validates them, and presents PRs for review. The human maintainer is the **senior** — reviews code, runs final checks, and merges approved PRs.

- AI **does**: write code, run validation, create commits via `but`, open PRs via `but pr new`, check konflate blast radius, report cautions.
- AI **does not**: merge PRs, push to `main` directly, approve its own changes, skip validation hooks, run `but pr auto-merge` or `but merge` without explicit human approval.
- Every change goes through `pre-commit` and the full validation pipeline before a PR is opened.
- The PR description must summarize what changed and why so the human reviewer can assess it efficiently.

### When to create PRs

- **Task complete**: when a discrete set of related, validated changes is done — commit, push, and open a PR.
- **Session end**: if there are uncommitted changes that pass validation, commit and open a PR before ending the session. Every session leaves a clean working tree or a ready-to-review PR.
- **One concern per PR**: separate unrelated changes into their own PRs so each can be reviewed and merged independently.

## Project layout

- `kubernetes/apps/` — App manifests organized by namespace (e.g. `observability/`, `media/`, `default/`).
- `kubernetes/flux/` — Flux GitOps config (cluster kustomizations, Helm repos, namespaces).
- `kubernetes/components/` — Shared Kustomize components (common labels, sops, gatus, volsync).
- `talos/` — Talos Linux node config, patches, and secrets.
- `scripts/` — Helper scripts for validation, backups, and DNS.
- `justfile` — All operations go through `just`. Run `just --list` to see available commands.

## Validation

- **BEFORE** committing, ALWAYS run `pre-commit run --all-files` and fix any errors first. The commit must pass all pre-commit checks.
- Run `just configure` to render templates, check secrets, and validate manifests.
- Run `just validate` to validate YAML schemas on source files via yayamlls.
- Run `just flate-test` to verify all Flux resources render successfully with flate.
- Run `python3 scripts/find_mistakes.py` to check for broken Kustomize references (needs `fd`).
- Add always new line at the end of files

## Talos changes

- Run `just talos-genconfig` to regenerate node configs after editing `talos/patches/`.
- Apply to each control plane node: `just talos-apply IP=192.168.69.110` (repeat for .111, .112).
- Static pod resources (apiserver, etcd, etc.) live in `talos/patches/controller/`. Always set both `requests` and `limits`.
- Check for OOM issues: `talosctl -n <node-ip> dmesg | grep -i "oom\|kill"`.
- Talos/K8s upgrades are automated via [tuppr](https://github.com/home-operations/tuppr) in `system-upgrade` namespace.
  - Renovate bumps versions in `TalosUpgrade`/`KubernetesUpgrade` CRs — merge the PR, Flux applies, tuppr orchestrates.
  - Upgrades run during maintenance window (Sunday 02:00 Europe/Paris) with Ceph noout pre/post hooks.
  - Manual upgrade still possible: `task talos:upgrade-node IP=192.168.69.110`.

## Secrets

- NEVER commit unencrypted secrets. All secrets use SOPS with Age encryption.
- Secret files are named `*.sops.yaml`. The `age.key` must never be committed.
- Ask the user to handle encryption, or use `just configure` to auto-encrypt.

## Commits and PRs

Use GitButler CLI (`but`) for all version control. Delegate VCS to the gitbutler skill for command detail. Never use `git add`, `git commit`, `git push`, or `gh pr create` for write operations. Never force-push, never skip hooks.

### Before committing

1. Always run `pre-commit run --all-files` and fix any errors.
2. Run the full validation pipeline if Kubernetes manifests changed:
   - `just configure` → `just validate` → `just flate-test` → `python3 scripts/find_mistakes.py`
3. Inspect the diff: `but diff` (selected dirty files/hunks), `but status` (commit/branch layout).

### Making commits

- Use `but commit <branch> -c -m "<msg>" --changes <ids>` to create a branch and commit in one step.
- Use file/hunk IDs from `but diff` — never stage blindly.
- Write concise, imperative-mood commit messages matching the existing repo style.

### Creating PRs

- Use `but pr new <branch-id> -m $'Title\n\nBody'` — it pushes the branch and creates the PR in one step (do not run `but push` first).
- The PR body must summarize what changed, why, and note any risks or cautions found.
- Present the PR URL to the human maintainer for review.

### Review flow

- After pushing, check konflate for blast radius: `konflate_list_pull_requests` → `konflate_get_pr_summary(<number>)`.
- Address any konflate cautions (data-loss, immutable-field, RBAC) before requesting review.
- Wait for CI (flate, yayamlls) to pass.
- Report the konflate summary and any cautions in the PR description so the human reviewer can assess risk.
- **Never merge your own PRs.** The human maintainer reviews and merges approved PRs.

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

- Metrics and logs ship to **self-hosted VM** (`metrics.internal`, `logs.internal`) via Alloy (in `observability` namespace).
- `kubernetes/apps/observability/grafana-cloud/` — Alloy deployment with River config (remote-writes to VM Prometheus/Loki).
- `kubernetes/apps/observability/kromgo/` — README badges, queries VM Prometheus API.
- `kubernetes/apps/observability/gatus/` — HTTP health checks, independent of metrics backend.
- `kubernetes/apps/observability/grafana/instance/` — Self-hosted Grafana instance managed by grafana-operator (ingress at grafana.internal).
- Exporters (node-exporter, kube-state-metrics, smartctl-exporter, etc.) run locally, scraped by Alloy via ServiceMonitors.
- Credentials stored in 1Password as `observability-vm` (Prometheus URL/user, Loki URL/user, API token).

## opencode agents and skills

This project has opencode agents and skills configured in `.opencode/` to speed up common tasks.

### Agents (`.opencode/agent/`)

- **cloudflare** — Cloudflare API ops for `juno.moe` zone: DNS, WAF rules, tunnel, Workers. Uses the globally installed Cloudflare MCP servers (cloudflare_docs, cloudflare_search, cloudflare_execute).
- **gitops** — Flux/Kustomize manifest work: repo layout, validation pipeline, konflate PR review, SOPS rules.
- **talos** — Talos Linux node operations: talosctl, patch regen, tuppr upgrades, OOM diagnostics.

### Skills (`.opencode/skills/`)

- **cloudflare** — How to use the Cloudflare MCP tools with zone specifics (WAF table, tunnel, DNS).
- **flux-validate** — The five-step validation pipeline in order with common failures and fixes.
- **sops-secrets** — SOPS/Age encryption workflow for creating and verifying `*.sops.yaml` files.

### Commands (`.opencode/command/`)

- `/validate` — Run the full validation chain (`just configure` → `just validate` → `just flate-test` → `find_mistakes.py` → `pre-commit`).

**Restart opencode after changing any file in `.opencode/`** — config is loaded at startup only.

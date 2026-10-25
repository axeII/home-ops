# AGENTS.md

Home-ops IaC repo — Kubernetes cluster managed with Flux CD, Talos Linux, and SOPS/Age encryption.

## Project model

Claude works as the **medior developer** — it implements changes, validates them, and presents PRs for review. The human maintainer is the **senior** — reviews code, runs final checks, and merges approved PRs.

- AI **does**: write code, run validation, create commits via `but`, open PRs via GitHub MCP tools (`github_create_pull_request`), check konflate blast radius, report cautions.
- AI **does not**: merge PRs, push to `main` directly, approve its own changes, skip validation hooks, run auto-merge, or merge without explicit human approval.
- Every change goes through `pre-commit` and the full validation pipeline before a PR is opened.
- The PR description must follow the shape under "Creating PRs" below. The reviewer skims it before reading the diff, so short and specific beats complete.

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

## Toolchain

Every CLI this repo needs is pinned in `mise.toml` at the repo root — `talosctl`, `kubectl`, `flux`,
`talhelper`, `sops`, `helmfile`, `stern`, `yq`, `jq`, `just`, `fd`, `pre-commit`, plus `flate` and
`yayamlls`. Install [mise](https://mise.jdx.dev) and run `just tools` (or `mise install`).

CI installs from the same `mise.toml` via `jdx/mise-action`, so local runs and the merge gate use
identical binaries. Do not install these tools by hand or with Homebrew — an unpinned copy on PATH
is exactly what made local validation diverge from CI before. `mise ls --current` shows what is
active.

mise also supplies `KUBECONFIG`, `SOPS_AGE_KEY_FILE`, and `TALOSCONFIG` via its `[env]` block. This
replaced direnv and `.envrc`; running both is explicitly unsupported by mise, so do not reintroduce
direnv.

## Validation

- **BEFORE** committing, ALWAYS run `pre-commit run --all-files` and fix any errors first. The commit must pass all pre-commit checks.
- Run `just configure` to encrypt any plaintext secrets and validate manifests.
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
  - Talos and Kubernetes arrive as separate PRs (`talos` and `kubernetes` groups). The `Find Mistakes` CI check fails a Kubernetes version the pinned Talos does not support, so a Kubernetes minor waits until the Talos upgrade that supports it has merged.
  - Before moving to a new Talos minor, add its row to `TALOS_KUBERNETES_SUPPORT` in `scripts/find_mistakes.py`. The check fails on a Talos minor it does not know.
  - Upgrades run during maintenance window (Sunday 02:00 Europe/Paris) with Ceph noout pre/post hooks.
  - Manual upgrade still possible: `task talos:upgrade-node IP=192.168.69.110`.

## Secrets

- NEVER commit unencrypted secrets. All secrets use SOPS with Age encryption.
- Secret files are named `*.sops.yaml`. The `age.key` must never be committed.
- Ask the user to handle encryption, or use `just configure` to auto-encrypt.

## Commits and PRs

Use GitButler CLI (`but`) for all version control writes (commits, branches, pushes). Delegate VCS to the
gitbutler skill for command detail. Use GitHub MCP tools (`github_create_pull_request`,
`github_issue_write`, etc.) for all GitHub API operations. Never use `git add`, `git commit`, `git push`,
or `gh pr create` for write operations. Never force-push, never skip hooks.

### Before committing

1. Always run `pre-commit run --all-files` and fix any errors.
2. Run the full validation pipeline if Kubernetes manifests changed:
   - `just configure` → `just validate` → `just flate-test` → `python3 scripts/find_mistakes.py`
3. Inspect the diff: `but diff` (selected dirty files/hunks), `but status` (commit/branch layout).

### Making commits

- Use `but commit -b <branch> -m "<msg>" <ids>` to create a branch and commit in one step.
- Use file/hunk IDs from `but diff` — never stage blindly.
- Write concise, imperative-mood commit messages matching the existing repo style.

### Creating PRs

1. Push the branch with `but push <branch-name>`.
2. Create the PR via MCP: `github_create_pull_request` with title, body (`head` branch, `base: "main"`, `owner: "axeII"`, `repo: "home-ops"`).
3. Write the body to the shape below.
4. Present the PR URL to the human maintainer for review.

#### PR body shape

Four headings, nothing else, whole body under 30 lines.

```markdown
## What
## Why
## Risk
## Validation
```

- One line under a heading is the target. Use bullets only for genuinely separate items.
- **What.** The resources or files that changed and the behaviour that changes with them. The reviewer has the diff, so do not restate it file by file.
- **Why.** The problem this solves, in a sentence or two. Link the issue instead of retelling it.
- **Risk.** Blast radius: namespaces touched, whether storage, networking or RBAC is involved, whether Flux restarts anything on reconcile. Konflate cautions go here. "None, docs only" is a complete answer.
- **Validation.** Which steps ran and that they passed. Name the steps, do not paste their output. Paste output only for a failure you are shipping around on purpose.
- Leave out session narrative, summary preambles, emoji headings, and tables of changed files.
- Investigation notes, rejected alternatives, and long logs go in a PR comment or a linked issue, not in the body.
- Run the `unslop` skill over the body before posting, if it is installed.

### Review flow

- After pushing, check konflate for blast radius: `konflate_list_pull_requests` → `konflate_get_pr_summary(<number>)`.
- Address any konflate cautions (data-loss, immutable-field, RBAC) before requesting review.
- Wait for CI (flate, yayamlls) to pass.
- Report the konflate summary and any cautions in the PR description so the human reviewer can assess risk.
- **Never merge your own PRs.** The human maintainer reviews and merges approved PRs.

### Creating issues

For bugs, tech debt, or tasks outside a PR workflow, create a GitHub issue. Use the `github` MCP server's structured tools for issue operations.

- `github_issue_write` with `method: "create"` — Create a new issue with title, body, labels, assignees.
- `github_search_issues` / `github_list_issues` — Find existing issues.
- Keep issues scoped to one concern. Reference related PRs/issues by number rather than summarizing them.

#### Issue body shape

Three headings, nothing else, whole body under 25 lines.

```markdown
## What
## Why
## What's needed
```

- **What** is the observed problem, **Why** is what it costs or blocks, **What's needed** is the fix or the next step to find one.
- Evidence gathered while investigating (logs, `kubectl` output, radar findings) goes in a follow-up comment, not the opening body. The body holds what a reader needs to decide whether to care.
- Run the `unslop` skill over the body before posting, if it is installed.

Fallback: `gh issue create` is also permitted if MCP tools are unavailable.

## CI tools

- **flate** — Offline Flux renderer. `flate test all --path kubernetes/flux` validates all resources render. Used in CI as a synchronous merge gate.
- **yayamlls** — YAML language server with Kubernetes schema validation. `yayamlls validate --render kubernetes/` validates source + rendered Flux output. Also provides editor LSP support via `.yayamlls.yaml`.
- **konflate** — PR review service deployed in the `flux-system` namespace. Renders PRs with flate, surfaces blast radius, image changes, and danger flags. Posts status checks and summary comments. Web UI at `konflate.juno.moe`.

## Observability

- Metrics and logs ship to **self-hosted VM** (`metrics.internal`, `logs.internal`) via Alloy (in `observability` namespace).
- `kubernetes/apps/observability/grafana-cloud/` — Alloy deployment with River config (remote-writes to VM Prometheus/Loki).
- `kubernetes/apps/observability/kromgo/` — README badges, queries VM Prometheus API.
- `kubernetes/apps/observability/gatus/` — HTTP health checks, independent of metrics backend.
- `kubernetes/apps/observability/grafana/instance/` — Self-hosted Grafana instance managed by grafana-operator (ingress at grafana.internal).
- Exporters (node-exporter, kube-state-metrics, smartctl-exporter, etc.) run locally, scraped by Alloy via ServiceMonitors.
- Credentials stored in 1Password as `observability-vm` (Prometheus URL/user, Loki URL/user, API token).

## Reference docs

- [Auto-merge policy](docs/auto-merge.md) — rules, gates, and quiet windows for the daily auto-merge workflow.
- [Cloudflare WAF rules](docs/cloudflare-waf.md) — required rules for the `juno.moe` zone.
- [GitHub Copilot CLI](docs/copilot-cli.md) — how agents and MCP config are shared with Copilot, and why `.github/agents/` is generated.

## Claude Code configuration

Lives in `.claude/` (tracked, reviewed like any change). `CLAUDE.md` imports this file.

- Agents: `cluster-radar` (read-only cluster triage via the radar MCP server, falls back to
  `kubectl`/`flux`/`talosctl`), `grafana-logs` (Loki/Prometheus queries, returns a summary plus a
  deeplink), `ship` (validate, commit with `but`, push, open PR; cannot merge). Delegate cluster and
  log investigation to them so the output stays out of the main context.
- Skills: `gitbutler`, `flux-validate`, `sops-secrets`. Cloudflare skills come from the `cloudflare`
  plugin enabled in `.claude/settings.json`.
- Commands: `/validate`, `/triage [namespace|app]`, `/ship [description]`.
- MCP servers (configured per-project in `~/.claude.json`, not in the repo, because of the Grafana
  token): `radar` at `http://localhost:49412/mcp` (Radar.app must be running; agents fall back and say
  so), `grafana` at `grafana.juno.moe` (Prometheus `PBFA97CFB590B2093`, Loki `P8E80F9AEF21F6940`),
  `github`.
- `.github/agents/*.agent.md` are generated from `.claude/agents/` by `scripts/sync_agents.py`; do not
  edit them by hand (pre-commit enforces this).

# home-ops

Kubernetes homelab managed with Flux CD, Talos Linux, and SOPS/Age. The full working agreement —
validation pipeline, commit and PR rules, auto-merge policy, cluster topology — is imported below.

## Start here

Delegate rather than investigating inline. Cluster state and log volume belong in a subagent's
context, not this one:

| Need | Use |
|---|---|
| Why is something broken in the cluster right now? | `cluster-radar` agent, or `/triage [namespace]` |
| What do the logs or metrics say over time? | `grafana-logs` agent |
| Add or rework an app under `kubernetes/apps/` | `app-builder` agent |
| Validate, commit, and open a PR | `ship` agent, or `/ship [description]` |
| Just run the validation chain | `/validate` |

### Delegation rules

These are rules, not suggestions. They apply whichever model the main session runs on.

- Commits, pushes and PRs always go through the `ship` agent. Never run `git commit`, `git push`
  or `github_create_pull_request` in the main session.
- Adding a new app, or reworking an existing one across several files, goes to the `app-builder`
  agent. When it reports back, pass its report to `ship` as the PR context.
- Small edits (a value, a version, one file) stay in the main session, then go to `ship`.

Before writing manifests, read the `flux-validate` skill for the validation pipeline and
`sops-secrets` before touching any `*.sops.yaml`. Version control is plain git: one branch per
change, never commits on `main`. The "Commits and PRs" section below has the rules.

@AGENTS.md

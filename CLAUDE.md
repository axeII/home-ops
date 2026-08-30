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
| Validate, commit, and open a PR | `ship` agent, or `/ship [description]` |
| Just run the validation chain | `/validate` |

Before writing manifests, read the `flux-validate` skill for the validation pipeline and
`sops-secrets` before touching any `*.sops.yaml`. Use `but` for every version control write — see
the `gitbutler` skill — never `git add`, `git commit`, or `git push`.

@AGENTS.md

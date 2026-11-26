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
| Review, validate, commit, and open a PR | `/home-ship [level] [description]` (alias `/shipit`) |
| Merge a PR the user asked to merge | `ship` agent |
| Just run the validation chain | `/validate` |

### Delegation rules

These are rules, not suggestions. They apply whichever model the main session runs on.

- Commits, pushes and PRs always go through the `ship` agent, reached by `/home-ship` so the change
  is code-reviewed first. Never run `git commit`, `git push` or `github_create_pull_request` in the
  main session.
- Merges go through the `ship` agent too, and only for a PR the user has asked to have merged.
  Relay their words to it.
- Adding a new app, or reworking an existing one across several files, goes to the `app-builder`
  agent. When it reports back, pass its report to `/home-ship` as the PR context.
- Small edits (a value, a version, one file) stay in the main session, then go to `/home-ship`.
- When the user says "ship it" or `/ship`, run `home-ship` (or its alias `shipit`). Never invoke a
  skill named `ship`: that name is Claude Code's built-in `/ship`, which is turned off here, so the
  call fails with "disabled ... in skillOverrides settings". That error is not a rule against
  shipping.

Before writing manifests, read the `flux-validate` skill for the validation pipeline and
`sops-secrets` before touching any `*.sops.yaml`. Version control is plain git: one branch per
change, never commits on `main`. The "Commits and PRs" section below has the rules.

@AGENTS.md

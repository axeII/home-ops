# Auto-merge policy

The `.github/workflows/auto-merge.yaml` workflow is scheduled Monday to Saturday at 02:00 UTC and
applies these rules. GitHub often starts scheduled runs hours late (7–10 h in November 2026), so
the quiet window below is checked when the run actually starts and again before each merge.

| Category | Detection | Min age | Days | Konflate gate |
|---|---|---|---|---|
| **patch / digest** | `type/patch`, `type/digest` | **2d** | any | no failures, no cautions |
| **minor** (release train) | `type/minor` | **3d** | **Fri–Sat** (Europe/Berlin) | no failures, no cautions |
| **major (ci/gh-action)** | `type/major` + `renovate/github-action` | **2d** | any | no failures (cautions allowed) |
| **major (other)** | `type/major`, not `renovate/github-action` | — | MANUAL | — |
| **critical infra** | `needs-review` label, or title/branch matches `ceph\|cilium\|flux\|dragonfly` | — | MANUAL | — |
| **area/talos** | `area/talos` label (`talos/**`) | — | MANUAL | — |

- **CI gate:** every row above also needs green CI. `.github/scripts/pr-ci-gate.sh` takes the latest
  run of each check on the head commit, and every one must have succeeded, been skipped, or be
  neutral. A failed, cancelled or still-running check skips the PR until the next run. The newest
  run of each workflow on the head commit must also have passed, not counting runs that
  `cancel-in-progress` cancelled. This catches a job that failed before GitHub created it, such as
  one with an empty matrix: it leaves no check behind, and GitHub's merge state ignores it. The head
  commit must also be at least 60 minutes old, and GitHub's merge state must be `CLEAN` or
  `HAS_HOOKS`. The merge passes `--match-head-commit`, so if Renovate pushes after the check, GitHub
  refuses the merge and the job fails instead of merging an unchecked commit. Run the script by hand
  to see why a PR is held: `.github/scripts/pr-ci-gate.sh <number>`.
- **Cluster quiet window:** no merges on Sunday (Talos/Kubernetes upgrade 02:00–06:00
  Europe/Paris, then recovery), or 23:00–02:00 Europe/Paris on any night, while backups run.
  Renovate's branch automerge of Grafana dashboards (`.renovate/grafanaDashboards.json5`) keeps
  the same hours.
- **Backups:** VolSync daily at 23:00 UTC, Kopia maintenance at 23:30 UTC, `pgbackup` Thursday
  23:00 Europe/Paris. VolSync and Kopia only take UTC, which puts them at 00:00–01:30 Paris in
  both winter and summer, so on Sundays they finish before the upgrade starts at 02:00.
- **Two phases:** every PR is evaluated first and the merge plan is printed; then the plan is merged.
- **Pause between merges:** 3 min for patch/digest/action-major, 5 min for minors, so Flux reconciles one change at a time. No pause after the last merge.
- **Run budget:** merging stops at 45 min and the rest of the plan is deferred to the next run. This keeps every merge inside the 1h lifetime of the GitHub App token. Any failed merge fails the job.
- Konflate re-render is triggered before each merge gate via `KONFLATE_PUSH_TOKEN`.
- **Defense in depth:** The `pr-classify` workflow applies `needs-review` and `risk/critical` labels to
  critical-infra PRs. Auto-merge hard-skips any PR with the `needs-review` label regardless of the
  title/branch regex — two independent detection layers must both fail for a critical upgrade to
  auto-merge.
- **Konflate** is reachable only from inside the home network (private IP). From GitHub Actions, the
  konflate gate is skipped — the auto-merge relies on label/age/day rules and the CI gate. A
  `Konflate` check that konflate did post is still judged by the CI gate, so a red one blocks the
  merge. `Konflate` as a required status check in branch protection won't work from outside the
  network.
- **Konflate write-back** posts a summary PR comment + commit status after each render when reachable (inside the network).
- **Setup:** add `KONFLATE_PUSH_TOKEN` (random 32-byte hex) to 1Password `konflate` item and as a GitHub Actions secret; confirm the GitHub App has `checks: write` + `pull-requests: write` permissions.

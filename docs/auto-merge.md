# Auto-merge policy

The `.github/workflows/auto-merge.yaml` workflow runs daily at 02:00 UTC and applies these rules:

| Category | Detection | Min age | Days | Konflate gate |
|---|---|---|---|---|
| **patch / digest** | `type/patch`, `type/digest` | **2d** | any | no failures, no cautions |
| **minor** (release train) | `type/minor` | **3d** | **Fri–Sat** (Europe/Berlin) | no failures, no cautions |
| **major (ci/gh-action)** | `type/major` + `renovate/github-action` | **2d** | any | no failures (cautions allowed) |
| **major (other)** | `type/major`, not `renovate/github-action` | — | MANUAL | — |
| **critical infra** | `needs-review` label, or title/branch matches `ceph\|cilium\|flux\|dragonfly` | — | MANUAL | — |
| **area/talos** | `area/talos` label (`talos/**`) | — | MANUAL | — |

- **Cluster quiet window:** Sun 00:00–05:00 UTC — no merges (Talos upgrade window).
- **Sleep between merges:** 300 seconds to let Flux reconcile before the next merge.
- Konflate re-render is triggered before each merge gate via `KONFLATE_PUSH_TOKEN`.
- **Bulk merge** (`.github/workflows/bulk-merge-prs.yaml`) also excludes rook-ceph, `area/talos`, `type/major`, `type/minor`, and `hold`.
- **Defense in depth:** The `pr-classify` workflow applies `needs-review` and `risk/critical` labels to
  critical-infra PRs. Auto-merge hard-skips any PR with the `needs-review` label regardless of the
  title/branch regex — two independent detection layers must both fail for a critical upgrade to
  auto-merge.
- **Konflate** is reachable only from inside the home network (private IP). From GitHub Actions, the
  konflate gate is skipped — the auto-merge relies on label/age/day rules alone. `Konflate` as a
  required status check in branch protection won't work from outside the network.
- **Konflate write-back** posts a summary PR comment + commit status after each render when reachable (inside the network).
- **Setup:** add `KONFLATE_PUSH_TOKEN` (random 32-byte hex) to 1Password `konflate` item and as a GitHub Actions secret; confirm the GitHub App has `checks: write` + `pull-requests: write` permissions.

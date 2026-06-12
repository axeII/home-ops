# Security Policy

This repository manages personal homelab infrastructure using Kubernetes, Flux CD,
and Talos Linux. It is not a traditional software project, so "vulnerabilities"
here typically mean leaked secrets, dangerous misconfigurations, or insecure
defaults in the committed configuration files.

## What to look for

- Unencrypted secrets or sensitive values committed in plaintext
- Misconfigured RBAC, network policies, or exposed services
- Insecure defaults in app configurations
- Anything that could expose the homelab to unintended access

## Out of scope

- CVEs in upstream container images or Helm charts — these are handled
  automatically by [Renovate](https://github.com/renovatebot/renovate)
- Issues with external services (Cloudflare, Proxmox, TrueNAS, etc.)

## Reporting

Feel free to open a PR if you find any security vulnerability in this repository.
Thank you 🙏

> **Note:** Never include actual secret values in a PR.
> If you discovered exposed credentials, please open an issue or contact me
> privately instead.

## Supply chain posture

Defenses in place to limit blast radius from compromised upstream packages
(npm/PyPI rapid-release attacks, malicious GitHub Actions, tag mutation):

- **GitHub Actions are SHA-pinned** via the `helpers:pinGitHubActionDigests`
  Renovate preset. New actions land unpinned and Renovate replaces version tags
  with immutable commit SHAs on the next run.
- **Container images are digest-pinned** by Renovate (`pinDigests: true` for
  the `docker` datasource). Tag-only references are gradually replaced with
  `image@sha256:...` form.
- **3-day release-age cooldown** on auto-merged patches. Gives the community
  time to revoke a malicious release before it lands here.
- **Auto-merge deny list** for high-blast-radius components (Plex, Rook-Ceph,
  Cilium, Talos, Flux operator/instance). These always require manual review.
- **Renovate vulnerability alerts** surface GHSA advisories as PRs labeled
  `security` for prioritized review.
- **Trivy** scans every container referenced in PR-changed YAML and uploads
  SARIF to the GitHub Security tab.
- **OpenSSF Scorecard** runs weekly and on push to `main`, flagging repo-level
  misconfigurations (missing branch protection, dangerous workflow patterns,
  etc.).
- **gitleaks** + **sops forbid-secrets** pre-commit hooks catch unencrypted
  secrets before they reach the index.
- **Secrets** are encrypted at rest with age via sops; runtime materialization
  is handled by external-secrets + 1Password Connect.

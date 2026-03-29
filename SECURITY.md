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

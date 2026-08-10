# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Start here

This repo already has a detailed agent playbook in **`AGENTS.md`** — read it before making changes. It covers the human/AI review model (AI proposes via PR, human merges), the full validation pipeline, Talos/secrets/PR workflows, the auto-merge policy, and the `.opencode/` agents and skills. Everything below is a Claude-Code-specific supplement, not a replacement.

## What this is

A homelab Kubernetes cluster (Talos Linux + Flux CD GitOps) managed entirely as code. Renovate opens dependency PRs, konflate renders the blast radius, CI validates, and an auto-merge policy deploys safe changes automatically — see `AGENTS.md` for the exact rules and `README.md` for the full stack/app inventory.

## Common commands

All commands go through `just` — run `just --list` for the full set. The core validation loop (run before every commit that touches `kubernetes/`):

```sh
just configure          # render templates, auto-encrypt any plaintext secrets, validate
just validate           # yayamlls schema validation (source + rendered Flux output)
just flate-test         # confirm all Flux resources render (flate)
python3 scripts/find_mistakes.py   # catch broken Kustomize references (needs `fd`)
pre-commit run --all-files          # full pre-commit suite, must pass before committing
```

Talos node changes: `just talos-genconfig` after editing `talos/patches/`, then `just talos-apply IP=<node-ip>` per control-plane node.

## Architecture at a glance

- `kubernetes/apps/<namespace>/<app>/` — each app is `app/` (HelmRelease, Kustomization, ExternalSecret, ...) + `ks.yaml` (the Flux Kustomization that wires it in). Reading an app usually means reading both.
- `kubernetes/flux/` — the meta layer: HelmRepository sources and the top-level cluster Kustomization that Flux bootstraps from.
- `kubernetes/components/` — shared Kustomize components (common labels, sops, gatus, keda/nfs-scaler, volsync) referenced across many apps rather than duplicated.
- `talos/patches/` — Talos machine config patches (global vs. controller-specific), rendered into node configs by `talhelper` via `just talos-genconfig`.
- Secrets are either SOPS+Age (`*.sops.yaml`, committed encrypted) or `ExternalSecret` resources backed by 1Password Connect — never plaintext in git.

## Knowledge graph (graphify)

This repo has a prebuilt, committed knowledge graph of the whole codebase under `graphify-out/` (nodes, edges, communities, god-node/surprising-connection analysis across every YAML, script, and doc). It was built with the `graphify` skill in `.claude/skills/graphify/` and is meant to travel with the repo so any agent on any machine can use it without re-extracting.

- For architecture questions ("how does X relate to Y", "what depends on Z", "trace this config's blast radius"), check the graph first: `graphify-out/GRAPH_REPORT.md` for a human-readable summary, or `/graphify query "<question>"` for a live traversal.
- If `kubernetes/**`, `talos/**`, or root docs change meaningfully, refresh it with `/graphify --update` (incremental — only re-extracts changed files).
- `graphify-out/cache/` is committed on purpose (content-addressed extraction cache, ~1.5M tokens' worth of prior work) so rebuilds are cheap. `graphify-out/cost.json` and the machine-local `.graphify_python`/`.graphify_root` files are gitignored — never commit those.

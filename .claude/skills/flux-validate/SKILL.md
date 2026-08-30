---
name: flux-validate
description: Flux/Kustomize validation pipeline for this home-ops repo. Use before committing changes to verify all manifests are correct. Trigger keywords: validate, render, flate, kustomize build, pre-commit, find_mistakes.
---

# Flux validation pipeline

Run these in order before any commit. Each step catches different issues.

## 1. `just configure`

Renders templates, verifies SOPS encryption, and validates manifests. Run first.

Common failures:

- Missing or unencrypted `*.sops.yaml` files
- Template rendering errors in YAML that uses env vars

## 2. `just validate`

Runs yayamlls Kubernetes schema validation on all YAML source files (including rendered Flux output).

Common failures:

- Wrong `apiVersion` or `kind` for the Kubernetes version
- Invalid field names or nesting in resources
- Schema violations in CRDs (may need updated schemas)

## 3. `just flate-test`

Offline Flux renderer. Simulates what Flux would produce from `kubernetes/flux/`. All Kustomizations and HelmReleases must resolve.

Common failures:

- Missing Kustomize dependency or base path
- HelmRelease referencing a chart repo that flate can't fetch
- Kustomize patch target not found
- Broken `ks.yaml` pointing to a non-existent `app/` directory

## 4. `python3 scripts/find_mistakes.py`

Scans for broken Kustomize references — paths to files or directories that don't exist. Requires `fd` (installed).

Common failures:

- `kustomizeconfig` or `resources` entries pointing to deleted files
- `patches` entries referencing old paths
- `namespace` mismatches between kustomization and ks.yaml location

## 5. `pre-commit run --all-files`

Final gate. Runs all pre-commit hooks (YAML lint, markdown lint, SOPS check, trailing whitespace, end-of-file fixer, etc.). All hooks must pass.

Failures here mean editing the source file to match hook expectations.

## Environment failures vs. real failures

Some failures come from the local toolchain, not from a change. The signature is that they fail
identically on a clean tree — check that before reporting a change as broken.

**`just flate-test` fails en masse with `403: denied` from ghcr.io**
Every failure reads `chart source OCIRepository/... not ready: ... response status code 403: denied`.
This is registry auth, not manifests. A stale or under-scoped credential in `~/.docker/config.json`
overrides anonymous access, which would otherwise succeed. Confirm with:

```bash
DOCKER_CONFIG=$(mktemp -d) just flate-test
```

If that passes, the repo is fine and the stored credential is the problem. GHCR pulls need a
**classic** PAT with `read:packages` (fine-grained tokens are not supported by GitHub Packages), or
no credential at all — these charts are public and anonymous pulls work.

**A pass does not prove auth works.** flate caches chart layers under `~/Library/Caches/flate`, so
one successful render keeps later runs green until a chart version changes — which is precisely
when Renovate bumps something and you need the check. To test auth for real, use a throwaway cache:

```bash
FLATE_CACHE_DIR=$(mktemp -d) just flate-test
```

Never edit manifests to chase these errors.

**`yayamlls` reports `schema load failed` for `token.sops.yaml` / `ceph-secrets.sops.yaml`**
Two files reference a third-party schema (`LeShaunJ/ops-schema`) whose upstream URL returns a
non-JSON body. Known noise — `yayamlls` still exits 0 and CI sees the same. Not a blocker.

**`python3 scripts/find_mistakes.py` warnings**
Warnings are not failures — the script exits 0. Two are currently expected on a clean tree
(unregistered `affine` app, missing common component in `rook-ceph`). Only act on warnings your
change introduced.

**Local tool versions**
`yayamlls` is installed via `go install github.com/home-operations/yayamlls/cmd/yayamlls@<version>`
into `~/go/bin`, pinned to the same version as `.github/workflows/yayamlls.yaml` so local results
match the merge gate. If `yayamlls: command not found`, either it is not installed or `~/go/bin` is
not on PATH.

## When validation fails

1. Read the error output carefully — each tool prints the file + line
2. Fix the underlying issue (not the symptom)
3. Re-run the failing step only (not the full pipeline) to confirm
4. Then re-run the full pipeline once before committing

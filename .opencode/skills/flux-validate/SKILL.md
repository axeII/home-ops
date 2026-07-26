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

## When validation fails

1. Read the error output carefully — each tool prints the file + line
2. Fix the underlying issue (not the symptom)
3. Re-run the failing step only (not the full pipeline) to confirm
4. Then re-run the full pipeline once before committing

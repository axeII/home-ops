# AGENTS.md

This document provides context and guidelines for AI agents working in this repository. The project is a "home-ops" Infrastructure-as-Code (IaC) repository managing a Kubernetes cluster using Flux CD, Talos Linux, and SOPS for secret management.

## Project Structure & Tooling

*   **Task (`task`)**: The primary entry point for all operations. Usage: `task <task_name>`.
*   **Flux CD**: Manages Kubernetes resources via GitOps.
*   **Talos Linux**: The underlying OS for the Kubernetes nodes.
*   **SOPS/Age**: Used for encrypting secrets. `age.key` is required (do not commit!).
*   **Kustomize**: Used for Kubernetes manifest composition.
*   **Pre-commit**: Enforces linting and formatting.

## Build, Lint, and Validation Commands

Before submitting changes, ensure all validations pass.

### 1. Main Validation Workflow
Run the configuration task which renders templates, checks secrets, and validates manifests:
```bash
task configure
```
*Note: This may ask for confirmation to overwrite files.*

### 2. Specific Validation Commands
*   **Validate Kubernetes Manifests:**
    Runs `kubeconform` against all manifests in `kubernetes/flux` and `kubernetes/apps` (including Kustomize builds).
    ```bash
    task kubernetes:kubeconform
    ```

*   **Check for Broken Kustomize References:**
    Scans `kustomization.yaml` files for missing file references.
    ```bash
    python3 scripts/find_mistakes.py
    ```
    *(Requires `fd` installed)*

### 3. Linting (Pre-commit)
Run all pre-commit hooks to check for YAML syntax, whitespace, and secrets:
```bash
pre-commit run --all-files
```
*Hooks include: `yamllint`, `trailing-whitespace`, `end-of-file-fixer`, `gitleaks`.*

### 4. Other Useful Tasks
*   `task --list`: List all available tasks.
*   `task reconcile`: Force Flux to reconcile the cluster.

## Code Style & Guidelines

### Kubernetes & YAML
*   **Formatting**:
    *   Indentation: 2 spaces.
    *   No tabs.
    *   No trailing whitespace.
    *   Line length: No hard limit (disabled in `.yamllint.yaml`), but keep it readable.
*   **Linter Rules (`.yamllint.yaml`)**:
    *   `truthy`: Use `"true"`, `"false"`, or `"on"` (quoted strings preferred for booleans in K8s to avoid type confusion).
    *   `comments`: at least 1 space from content.
*   **Structure**:
    *   Applications go in `kubernetes/apps/<namespace>/<app_name>`.
    *   Cluster config goes in `kubernetes/flux`.
    *   Use `kustomization.yaml` to aggregate resources.

### Secrets Management
*   **NEVER commit unencrypted secrets.**
*   Use SOPS with Age encryption.
*   Secrets should be in files named `*.sops.yaml` or similar, which are ignored by some linters but checked by `gitleaks`.
*   If you need to add a secret, ask the user to handle the encryption or use the `task bootstrap:secrets` flow if appropriate.

### Scripts
*   **Bash**: Use `set -o errexit` and `set -o pipefail`. Validate inputs.
*   **Python**: Follow basic PEP8. Used mostly for utility scripts in `scripts/`.

### Error Handling
*   Tasks should fail fast.
*   When writing scripts, ensure exit codes are passed through correctly.

## Interaction Guidelines for Agents
1.  **Safety First**: Do not run `task configure` or `task bootstrap:*` without understanding the impact, as they can overwrite files.
2.  **Context**: Always check `Taskfile.yaml` and included taskfiles to understand how commands are constructed.
3.  **Verification**: After modifying YAML files, always run `task kubernetes:kubeconform` and `pre-commit run --all-files` to verify validity.
4.  **Files**: When creating new apps, follow the pattern of existing apps in `kubernetes/apps`.

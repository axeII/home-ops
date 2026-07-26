---
name: sops-secrets
description: SOPS/Age secret management for this repo. Use when creating, editing, encrypting, or verifying encrypted secrets. Trigger keywords: secret, sops, age, encrypt, decrypt, *.sops.yaml.
---

# SOPS/Age secrets

All secrets in this repo are encrypted with SOPS using Age.

## Rules

- **NEVER** commit unencrypted secrets. The CI and pre-commit hooks will reject them.
- Secret files are named `*.sops.yaml` (e.g., `externalsecret.sops.yaml`, `helmrelease.sops.yaml`)
- The `age.key` file at the repo root must NEVER be committed (it's in `.gitignore` but verify before staging)
- Unencrypted temp files with real secrets must never be committed

## Workflow

### Creating a new secret

1. Create the file as a plain YAML with the `.sops.yaml` extension
2. Run `just configure` — this auto-encrypts the file with SOPS
3. Verify it's encrypted: check that the file starts with `sops:` or has `encrypted_regex` entries

### Editing an existing secret

1. Decrypt with `sops -d <file>` to read the content (read-only; do not write the decrypted output)
2. Use `just configure` to re-encrypt after making changes
3. Alternatively, use `sops <file>` which opens in an editor and encrypts on save — but the agent should NOT do this interactively

### Verifying before commit

Before committing, verify all staged `*.sops.yaml` files are encrypted:

```bash
# Check that sops files are actually encrypted
for f in $(git diff --cached --name-only -- '*.sops.yaml'); do
  head -1 "$f" | grep -q '^sops:' || echo "UNENCRYPTED: $f"
done
```

If any file shows as UNENCRYPTED, run `just configure` to fix it.

## Other encryption

- `.sops.yaml` is the SOPS config file at the repo root — it defines which files are encrypted and with which key
- `age.key` at repo root is the local Age private key — never commit, never share

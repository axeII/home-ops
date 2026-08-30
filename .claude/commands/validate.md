---
description: Run the full home-ops validation chain, stopping at the first failure
---

# Validate

Run the validation pipeline in order. Stop at the first failing step.

```bash
just configure
just validate
just flate-test
python3 scripts/find_mistakes.py
pre-commit run --all-files
```

Steps 1-4 may be skipped only if nothing under `kubernetes/` or `talos/` has changed — check with
`git status` first. Step 5 always runs.

If a step fails: report which step, quote the error, and diagnose the underlying cause. Fix it, re-run
that step alone to confirm, then re-run the full chain once.

Before blaming a change, check the **Environment failures vs. real failures** section of the
`flux-validate` skill — several steps currently fail on a clean tree for local-toolchain reasons and
must not be reported as change-induced.

If everything passes, say so in one line — no step-by-step narration of a green run.

Consult the `flux-validate` skill for what each step catches and its common failure modes.

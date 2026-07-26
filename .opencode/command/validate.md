---
description: Run the full validation pipeline and report failures.
---

Run the full validation chain:

1. `just configure`
2. `just validate`
3. `just flate-test`
4. `python3 scripts/find_mistakes.py`
5. `pre-commit run --all-files`

If any step fails, report which step and what error it produced. Do not proceed to the next step if the current one fails.

---
description: Validate, commit, push, and open a PR for the current changes
argument-hint: "[what the change does]"
---

# Ship

Ship the current working tree for review: **$ARGUMENTS**

Delegate to the `ship` subagent. Give it the description above (or, if none was given, summarize the
changes yourself from `but diff` and pass that along) plus any context from this session it needs to
write an accurate PR body — what problem the change solves, anything you worked around, anything a
reviewer should look at closely.

It will run the full validation chain, commit with `but` using hunk IDs from the diff, push, and open
the PR. It cannot merge, and it will split unrelated changes into separate PRs.

Relay the PR URL and the summary back to the user — the agent's report is not shown to them.

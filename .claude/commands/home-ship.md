---
description: Review the current changes with code-review, then validate, commit, push and open a PR through the ship agent
argument-hint: "[low|medium|high|xhigh|max] [what the change does] [and merge it]"
---

# Home ship

Ship the current changes for review: **$ARGUMENTS**

Two steps, in order. The review runs here in the main session because the `ship` agent has no
Skill tool. The commit runs in the agent because the delegation rules keep `git commit` and
`git push` out of the main session.

## 1. Review

A leading `low`, `medium`, `high`, `xhigh` or `max` in the arguments is the review level; the rest
is the change description. `ultra` is a billed cloud review only the user can launch: tell them to
run `/code-review ultra` themselves, and stop.

Run the `code-review` skill on the changes about to ship, passing the level when one was given. The
target is the working-tree diff, or the branch against `origin/main` when the tree is clean. With
neither, there is nothing to ship: say so and stop.

Then settle every finding:

- A real problem: fix it here. Review fixes are small edits, which stay in the main session.
- Not a problem, or outside this change: leave it, with the reason in a few words.

The step is done when every finding is fixed or carries a reason. The fixes stay uncommitted for
the agent to commit.

## 2. Ship

Delegate to the `ship` agent. Its prompt carries:

- the change description, or your summary from `git diff` when none was given;
- the review outcome in one line: level, findings fixed, findings left open with their reasons;
- what the PR body needs from this session: the problem the change solves, anything worked around,
  anything a reviewer should look at closely;
- the merge instruction. When the user asked in this session for this PR to be merged (`and merge
  it` in the arguments, say), quote their words and any merge method they named. Otherwise write
  "Do not merge."

The agent's report is not shown to the user: relay the PR URL, the review outcome and its summary.

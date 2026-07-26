# GitButler CLI Key Concepts

Deep dive into GitButler's conceptual model and philosophy.

## The Workspace Model

### Traditional Git: Serial Branching

```
main ──┬── feature-a (checkout here, work, commit, checkout back)
       └── feature-b (checkout here, work, commit, checkout back)
```

- Work on ONE branch at a time
- Switch contexts with `git checkout`
- Changes are isolated by branch

### GitButler: Parallel Stacks

```
workspace (gitbutler/workspace)
  ├─ feature-a (applied, merged into workspace)
  ├─ feature-b (applied, merged into workspace)
  └─ feature-c (unapplied, not in workspace)
```

- Work on MULTIPLE branches simultaneously
- No context switching - all applied branches merged in working directory
- Changes are ASSIGNED to branches, not isolated by checkout

### Key Implications

1. **No `git checkout`**: You don't switch between branches. All applied branches exist simultaneously in your workspace.

2. **The `gitbutler/workspace` branch**: A merge commit containing all applied stacks. Don't interact with it directly - use `but` commands.

3. **Applied vs Unapplied**: Control which branches are active:
   - Applied branches: In your working directory
   - Unapplied branches: Exist but not active
   - Use `but apply`/`but unapply` to control

## CLI IDs: Short Identifiers

Every object gets a short, human-readable CLI ID shown in `but status`. IDs are generated per-session and are unique across all entity types (no two objects share an ID) — always read them from `but status`.

```
Commits:    1, kyn, mpq#0  (short change-ID prefix when the commit has one, sha prefix otherwise;
                             a #N suffix disambiguates commits sharing a change ID)
Branches:   fe, bu, ui     (unique 2–3 char substring of the branch name, e.g. "fe" from "feature-x";
                             falls back to auto-generated ID if no unique substring exists)
Files:      g, qs, uo      (derived from the file path, long enough to be unique)
Hunks:      g:5, uo:d      (<file-id>:<hunk-id>; the hunk part is derived from the hunk's content)
Committed files: kyn:n     (<commit-id>:<file-id>, shown under each commit in `but status -fv`)
Stacks:     m0, n0          (auto-generated, 2–3 chars)
```

**Why?** Git commit SHAs are long (40 chars). CLI IDs are short, variable-length, and unique within your current workspace context. Commits, files, and hunks may use a single character when that is unambiguous.

**Reading status output:** the first token on each line is that line's ID. Verbose commit lines append an informational `(sha …)` after the timestamp — it changes on every amend; do not pass it to commands.

**Stability:** File/hunk IDs copied from the current output generally remain usable across ordinary commits, so you can reference several in a row, including across chained `but commit` calls. If an ID stops resolving, re-read the diff and continue. Commit IDs are change-ID prefixes when the commit has a change ID and sha prefixes otherwise. Change-ID refs survive history edits (`amend`, `squash`, `move`, `uncommit`, `reword`); sha refs and `#N`-suffixed refs do not — a stale sha can silently resolve to the wrong commit. History edits may run in sequence off one status read when every ref involved is a change-ID ref; otherwise run them one at a time and take the next ref from the returned workspace state.

**Usage:** Pass these IDs as arguments to commands:

```bash
but commit <branch-id> -m "message"      # Commit to branch
but amend <commit-id> --changes <file-or-hunk-id>,<file-or-hunk-id>  # Amend file(s) or hunk(s) into commit
but rub <commit-id> <commit-id>          # Squash commits
```

## Parallel vs Stacked Branches

### Parallel Branches (Independent Work)

Create with `but branch new <name>`:

```
main ──┬── api-endpoint (independent)
       └── ui-update    (independent)
```

Use when:

- Tasks don't depend on each other
- Can be merged independently
- No shared code between them

Example: Adding a new API endpoint and updating button styles are independent.

### Stacked Branches (Dependent Work)

**To stack an existing branch** on top of another: `but move <child-branch-name> <parent-branch-name>`.

**To create a new stacked branch** from scratch: `but branch new <name> -a <anchor>` — only use this when the child branch doesn't exist yet.

```
main ── authentication ── user-profile ── settings-page
        (base)            (stacked)       (stacked)
```

Use when:

- Feature B needs code from Feature A
- Building incrementally on previous work
- Creating a series of related changes

Example: User profile page needs authentication to be implemented first.

**Stacking two existing branches:** If both branches already exist and you need to make one depend on the other, use top-level `move`:
```bash
but move feature/frontend feature/backend
# Now frontend is stacked on top of backend — both in the same stack
```

To tear off a branch from a stack:

```bash
but move feature/frontend zz
```

**Dependency tracking:** GitButler automatically tracks which changes depend on which commits. A dependent change can only be committed to the stack that contains the commits it depends on.

## The `but rub` Philosophy

`but rub` is the core primitive operation: "rub two things together" to perform an action.

### What Happens Based on Types

The operation performed depends on what you combine:

| Source | Target | Operation              | Example         |
| ------ | ------ | ---------------------- | --------------- |
| File   | Commit | Amend file into commit | `but rub a1 nn` |
| Commit | Commit | Squash commits         | `but rub mm nn` |
| Commit | Branch | Move commit to branch  | `but rub mm bu` |
| Commit | `zz`   | Undo commit            | `but rub mm zz` |

`zz` is a special target meaning "uncommitted" (no branch).

### Higher-Level Conveniences

These commands are wrappers around `but rub`:

- `but amend` = explicitly amend uncommitted files/hunks into a known commit
- `but squash` = Multiple `but rub <commit> <commit>` operations
- `but move` = commit move/reorder with position control, plus branch stack/tear-off (`<branch> <target-branch>` and `<branch> zz`)

**Why this design?** One powerful primitive is easier to understand and maintain than many specialized commands. Once you understand `but rub`, you understand the editing model.

## Dependency Tracking

GitButler tracks dependencies between changes automatically.

### How It Works

```
Commit C1: Added function foo()
Commit C2: Added function bar()
Uncommitted: Call to foo() in new code
```

The uncommitted change **depends on** C1 (because it calls `foo()`).

**Implications:**

1. Can't commit this change to a stack that doesn't contain C1
2. When amending it into history, it belongs in C1 (or a commit after C1)
3. If you try to move the change, GitButler prevents invalid operations

### Why This Matters

Prevents you from creating broken states:

- Can't move dependent code away from its dependencies
- Can't commit changes to the wrong stack
- Ensures each branch remains independently functional

## Empty Commits as Placeholders

You can create empty commits:

```bash
but commit empty --before nn
but commit empty --after nn
```

**Use cases:**

1. **Mark future work:** Create empty commit as placeholder for changes you'll make
2. **Organize history:** Add semantic markers in commit history

Example workflow:

```bash
but commit empty --before rr -m "TODO: Add error handling"
# Later, amend the error handling changes into the placeholder
but amend <empty-commit-id> --changes <file-id>
```

## Operation History (Oplog)

Every operation in GitButler is recorded in the oplog (operation log).

### What Gets Recorded

- Branch creation/deletion
- Commits
- Rub/squash/move operations
- Push/pull operations

### Using Oplog

```bash
but oplog                      # View history
but undo                       # Undo last operation
but redo                       # Redo last undone operation
but oplog list --since <snapshot-id>
but oplog list --snapshot
but oplog snapshot -m "known good"
but oplog restore <snapshot-id>  # Restore to specific point
```

Think of it as "git reflog" but for all GitButler operations, not just branch movements.

**Safety net:** Made a mistake? `but undo` it. Experimented and want to go back? `but oplog restore` to earlier snapshot.

## Applied vs Unapplied Branches

Branches can be in two states:

### Applied Branches

- Active in your workspace
- Merged into `gitbutler/workspace`
- Changes visible in working directory
- Can make changes and commit

### Unapplied Branches

- Exist but not active
- Not in working directory
- Can't make changes (must apply first)
- Useful for temporarily setting aside work

### Controlling State

```bash
but apply <branch-name>    # Make branch active
but unapply <id>           # Make branch inactive
```

**Use cases:**

- Unapply branches causing conflicts
- Focus on subset of work (unapply others)
- Temporarily set aside work without deleting

## Conflict Resolution Mode

When `but pull` causes conflicts, affected commits are marked as conflicted.

### Resolution Workflow

1. **Identify:** the `but pull` summary lists each conflicted commit's ID, oldest first (`but status` also shows them)
2. **Enter mode:** `but resolve <commit-id>` — it prints the conflict regions with line numbers. With several conflicted commits, resolve the oldest first: finishing a lower commit rebases the ones above it
3. **Fix conflicts:** Edit files, remove conflict markers (`but resolve status` re-lists what remains when several files are conflicted)
4. **Finalize:** `but resolve finish` or `but resolve cancel` — finish reports leftover markers and the surviving uncommitted changes, so no follow-up check is needed

### During Resolution

- You're in a special mode focused on that commit
- Other GitButler operations are limited
- `but status` shows you're in resolution mode
- Must finish or cancel before continuing normal work

## Read-Only Git Commands

Git commands that don't modify state are safe to use:

**Safe (read-only):**

- `git log` - View history
- `git diff` - See changes (but prefer `but diff` — it supports CLI IDs)
- `git show` - View commits
- `git blame` - See line history
- `git reflog` - View reference log

**Don't use in a GitButler workspace:**

- `git status` - Misleading: shows merged workspace state, not individual stacks; missing CLI IDs that agents need
- `git commit` - Commits to the workspace merge commit, not your branch
- `git checkout` - Breaks workspace model
- `git rebase` - Conflicts with GitButler's management
- `git merge` - Use `but land` instead

**Rule of thumb:** If it reads, it's fine. If it writes, use `but` instead.

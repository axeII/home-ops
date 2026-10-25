# GitHub Copilot CLI

Copilot CLI works in this repo too, sharing the same instructions and an equivalent set of agents.

## What is shared automatically

Copilot CLI discovers `AGENTS.md` and `CLAUDE.md` at the repository root on its own, and supports
the same `@relative/path` include syntax, so `CLAUDE.md` → `@AGENTS.md` resolves there exactly as
it does in Claude Code. **This file is the single source of truth for both tools** — no
`.github/copilot-instructions.md` is needed, and adding one would only duplicate this.

## Agents (`.github/agents/*.agent.md`)

The same three agents as `.claude/agents/`, in Copilot's schema — `cluster-radar`, `grafana-logs`,
and `ship`, with the same read-only and no-merge boundaries. Invoke one with:

```bash
copilot --agent cluster-radar -p "<question>"
```

Repository agents live in `.github/agents/`; user-level ones in `~/.copilot/agents/`, and a
user-level agent of the same name wins.

**`.github/agents/*.agent.md` is generated — do not edit it.**

Copilot CLI *does* read `.claude/agents/*.md`, so symlinking the two directories — the usual advice
for sharing AI config — looks like it works. It does not, and it fails silently. Verified against
CLI v1.0.82:

| Agent file | `tools:` entry | Result |
| --- | --- | --- |
| `.claude/agents/probe.md` | `mcp__github__get_me` | **silently dropped**; agent had built-ins only |
| `.github/agents/probe.agent.md` | `github/get_me` | granted and invoked successfully |

This is deliberate on GitHub's part — the docs state that "all unrecognized tool names are ignored,
which allows product-specific tools to be specified in an agent profile without causing problems."
That tolerance is what makes sharing *instruction* files across tools work so well, and it is
exactly what makes sharing *agent* files dangerous: `cluster-radar` symlinked into Copilot would
load cleanly, report no error, and have zero radar tools.

Two facts worth keeping in mind:

- `.github/agents/` **wins** over `.claude/agents/` on a name conflict, so the generated files are
  the ones in effect. Deleting them does not fall back gracefully — it silently strips every MCP
  tool from all three agents.
- Copilot ignores `model:` with a warning (`specifies model "inherit" which is not available`), so
  model selection cannot be shared either.

The bodies are identical, so `.claude/agents/` is the single source and the Copilot copies are
generated from it:

```bash
python3 scripts/sync_agents.py           # regenerate after editing .claude/agents/
python3 scripts/sync_agents.py --check   # what the pre-commit hook runs
```

The `sync-agents` pre-commit hook fails on any drift in either direction — an edit to a source
that was not regenerated, or a hand-edit to a generated file. If an agent gains a tool with no
Copilot equivalent, the script exits with the tool name rather than silently dropping it; add the
mapping to `BUILTINS` in the script.

## MCP servers for Copilot

Copilot CLI reads `~/.copilot/mcp-config.json` — it does **not** auto-load a repo-level
`.github/mcp.json` (that path applies to other Copilot surfaces). `github-mcp-server` is built in,
so only `radar` and `grafana` need configuring, and both live in the user config because of the
Grafana token.

`.github/mcp.json` is kept as the committed, secret-free definition of the radar server. Apply it
explicitly with:

```bash
copilot --additional-mcp-config @.github/mcp.json
```

## Not shared

Slash commands (`.claude/commands/`) and skills (`.claude/skills/`) are Claude Code only. Copilot
CLI can load `.github/skills/`, but the skills are not duplicated there — their content is either
already in this file or reachable by reading `.claude/skills/`.

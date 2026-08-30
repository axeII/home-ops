#!/usr/bin/env python3
"""Generate .github/agents/*.agent.md (Copilot CLI) from .claude/agents/*.md.

The two tools need the same agent definitions but cannot share a file: the tool
namespaces are incompatible (``mcp__radar__diagnose`` vs ``radar/diagnose``), so
a symlink would leave one of them with an unusable frontmatter. The bodies are
identical, so the Copilot copy is generated instead of maintained by hand.

Usage:
    python3 scripts/sync_agents.py            # regenerate
    python3 scripts/sync_agents.py --check    # fail if out of date (pre-commit)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / ".claude" / "agents"
DST = REPO / ".github" / "agents"

# Claude built-in tool -> Copilot built-in tool. Unlisted names are a hard error
# rather than a silent drop: a missing tool is an agent that fails at runtime.
BUILTINS = {
    "Read": "read",
    "Grep": "search",
    "Glob": "search",
    "Bash": "execute",
    "Edit": "edit",
    "Write": "edit",
}

BANNER = (
    "<!-- Generated from .claude/agents/{src} by scripts/sync_agents.py. "
    "Edit that file, not this one. -->"
)


def split_frontmatter(text: str, path: Path) -> tuple[list[str], str]:
    lines = text.split("\n")
    if lines[0] != "---":
        sys.exit(f"{path}: expected frontmatter to open with ---")
    try:
        end = lines.index("---", 1)
    except ValueError:
        sys.exit(f"{path}: unterminated frontmatter")
    return lines[1:end], "\n".join(lines[end + 1 :])


def convert_tools(value: str, path: Path) -> list[str]:
    out: list[str] = []
    for raw in value.split(","):
        name = raw.strip()
        if not name:
            continue
        if name.startswith("mcp__"):
            parts = name.split("__", 2)
            if len(parts) != 3:
                sys.exit(f"{path}: cannot parse MCP tool {name!r}")
            mapped = f"{parts[1]}/{parts[2]}"
        elif name in BUILTINS:
            mapped = BUILTINS[name]
        else:
            sys.exit(
                f"{path}: no Copilot equivalent known for tool {name!r}. "
                f"Add it to BUILTINS in {Path(__file__).name}."
            )
        if mapped not in out:  # Grep and Glob both map to search
            out.append(mapped)
    return out


def render(path: Path) -> str:
    fm, body = split_frontmatter(path.read_text(), path)
    fields: dict[str, str] = {}
    for line in fm:
        if ":" not in line:
            sys.exit(f"{path}: unexpected frontmatter line {line!r}")
        key, _, value = line.partition(":")
        fields[key.strip()] = value.strip()

    for required in ("name", "description", "tools"):
        if required not in fields:
            sys.exit(f"{path}: frontmatter is missing {required!r}")

    tools = json.dumps(convert_tools(fields["tools"], path))
    # 'model' is intentionally dropped: Copilot CLI selects the model itself.
    head = "\n".join(
        [
            "---",
            f"name: {fields['name']}",
            f"description: {fields['description']}",
            f"tools: {tools}",
            "---",
            "",
            BANNER.format(src=path.name),
        ]
    )
    return f"{head}\n{body}"


def main() -> int:
    check = "--check" in sys.argv[1:]
    sources = sorted(SRC.glob("*.md"))
    if not sources:
        sys.exit(f"no agents found in {SRC}")

    stale: list[str] = []
    for src in sources:
        dst = DST / f"{src.stem}.agent.md"
        want = render(src)
        have = dst.read_text() if dst.exists() else None
        if want == have:
            continue
        if check:
            stale.append(f"  {dst.relative_to(REPO)} (from {src.relative_to(REPO)})")
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_text(want)
            print(f"wrote {dst.relative_to(REPO)}")

    for dst in sorted(DST.glob("*.agent.md")):
        if not (SRC / f"{dst.name.removesuffix('.agent.md')}.md").exists():
            stale.append(f"  {dst.relative_to(REPO)} has no source in .claude/agents/")

    if stale:
        print("Copilot agents are out of sync with .claude/agents/:", file=sys.stderr)
        print("\n".join(stale), file=sys.stderr)
        print("\nRun: python3 scripts/sync_agents.py", file=sys.stderr)
        return 1
    if check:
        print(f"{len(sources)} agents in sync")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

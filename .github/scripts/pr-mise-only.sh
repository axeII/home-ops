#!/usr/bin/env bash
# Exit 0 when pull request <number> changes mise.toml and no other file, and
# leaves talosctl and kubectl alone.
#
# Such a PR only moves the pinned workstation and CI tools, so Flux has nothing
# to deploy from it. talosctl and kubectl move with the cluster in the talos
# and kubernetes Renovate groups, so a PR that touches them never passes, even
# if Renovate opens the group before its topf.yaml or tuppr CR change. Any gh
# error also exits non-zero, which keeps the PR on the manual path.
#
# Usage: .github/scripts/pr-mise-only.sh <number>
set -euo pipefail

files="$(gh pr view "$1" --json files --jq '[.files[].path] | join(",")')"
[ "${files}" = "mise.toml" ] || exit 1

diff="$(gh pr diff "$1")"
if grep -qE '^[-+](talosctl|kubectl) *=' <<<"${diff}"; then
  exit 1
fi

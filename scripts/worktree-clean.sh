#!/usr/bin/env bash
# Remove local branches, and their worktrees, whose PR has merged.
#
#   scripts/worktree-clean.sh          list what would go, delete nothing
#   scripts/worktree-clean.sh --yes    delete it
#
# A branch is removed only when every local commit reached a merged PR. It is
# kept when its worktree has uncommitted or gitignored files, or is the main
# checkout or the one this runs from.
set -euo pipefail
apply=false
for arg in "$@"; do
    case "$arg" in
        --yes) apply=true ;;
        *) echo "unknown argument: $arg (only --yes is accepted)" >&2; exit 2 ;;
    esac
done
root="$(cd "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")" && pwd -P)"
here="$(cd "$(git rev-parse --show-toplevel)" && pwd -P)"
cd "$root"
git fetch --quiet --prune origin
if $apply; then git worktree prune; fi
prs="$(mktemp)"
trap 'rm -f "$prs"' EXIT
echo "Fetching PR list from GitHub..."
gh pr list --state all --limit 100000 --json headRefName,number,state,headRefOid \
    --jq '.[] | [.headRefName, .number, .state, .headRefOid] | @tsv' > "$prs"
n_wt=0 n_br=0 kb=0 n_kept=0
while read -r branch <&3; do
    [[ "$branch" == main ]] && continue
    tip="$(git rev-parse "refs/heads/$branch")"
    wt="$(git worktree list --porcelain | awk -v ref="branch refs/heads/$branch" \
        '/^worktree /{p=substr($0,10)} $0==ref{print p}')"
    reason="" merged="" real=""
    if [[ -n "$wt" && -d "$wt" ]]; then real="$(cd "$wt" && pwd -P)"; fi
    if [[ "$real" == "$root" ]]; then
        reason="checked out in the main checkout"
    elif [[ "$real" == "$here" ]]; then
        reason="running from this worktree"
    elif [[ -n "$real" && -n "$(git -C "$wt" status --porcelain)" ]]; then
        reason="uncommitted changes"
    elif [[ -n "$real" ]] \
        && ignored="$(git -C "$wt" ls-files --others --ignored --exclude-standard --directory | sed -n 1p)" \
        && [[ -n "$ignored" ]]; then
        reason="gitignored files ($ignored)"
    else
        # Safe only if every local commit reached a merged PR: the tip is that PR's head or an ancestor of it.
        while IFS=$'\t' read -r _ num state oid; do
            [[ "$state" == MERGED ]] || continue
            if [[ "$oid" == "$tip" ]]; then merged="$num"; break; fi
            git cat-file -e "$oid^{commit}" 2>/dev/null || git fetch --quiet origin "refs/pull/$num/head" 2>/dev/null \
                || { reason="could not fetch head of merged PR #$num"; continue; }
            if git merge-base --is-ancestor "$tip" "$oid" 2>/dev/null; then merged="$num"; break; fi
            reason="commits after merged PR #$num"
        done < <(awk -F'\t' -v b="$branch" '$1==b' "$prs")
        if [[ -z "$merged" && -z "$reason" ]]; then
            reason="$(awk -F'\t' -v b="$branch" '$1==b{print "PR #" $2 " " tolower($3); exit}' "$prs")"
            if [[ -z "$reason" ]]; then
                if git show-ref --quiet "refs/remotes/origin/$branch"; then reason="pushed, no PR"; else reason="never pushed"; fi
            fi
        fi
    fi
    if [[ -z "$merged" ]]; then
        n_kept=$((n_kept + 1))
        printf 'keep    %-40s %s%s\n' "$branch" "$reason" "${wt:+  [worktree ${wt}]}"
        continue
    fi
    size=0
    if [[ -n "$wt" && -d "$wt" ]]; then size="$(du -sk "$wt" | cut -f1)"; fi
    if $apply; then
        if [[ -n "$wt" ]] && ! git worktree remove "$wt"; then
            printf 'skip    %-40s git refused to remove %s\n' "$branch" "$wt"
            continue
        fi
        git branch --quiet -D "$branch"
    fi
    printf 'remove  %-40s PR #%s merged%s\n' "$branch" "$merged" "${wt:+  [worktree ${wt}]}"
    n_br=$((n_br + 1))
    if [[ -n "$wt" ]]; then n_wt=$((n_wt + 1)); kb=$((kb + size)); fi
done 3< <(git for-each-ref --format='%(refname:lstrip=2)' refs/heads)
echo
if $apply; then
    echo "Removed $n_br branches, $n_wt of them with a worktree ($((kb / 1024)) MB). Kept $n_kept."
else
    echo "Would remove $n_br branches, $n_wt of them with a worktree ($((kb / 1024)) MB). Would keep $n_kept."
    echo "Run 'just worktree-clean --yes' to delete them."
fi

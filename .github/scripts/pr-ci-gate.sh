#!/usr/bin/env bash
# Usage: pr-ci-gate.sh <pr-number> [<expected-head-sha>]
#
# Decides whether a PR's CI allows an unattended merge. Prints one line
# saying why, and exits 0 only when all of these hold:
#   - the head commit is <expected-head-sha>, when one is given
#   - the latest run of every check on the head commit succeeded, was
#     skipped, or was neutral (failed, cancelled, timed out, or still
#     running all block)
#   - at least one check has reported
#   - no workflow run on the head commit is still queued or running, and
#     the newest run of each workflow that was not cancelled succeeded,
#     was skipped, or was neutral
#   - the head commit is at least MIN_COMMIT_AGE_MIN minutes old
#   - GitHub's merge state is CLEAN or HAS_HOOKS
#
# Checks are judged one by one rather than through GitHub's rollup state,
# which counts superseded runs (cancelled by `cancel-in-progress`) as
# failures in some queries and not in others.
#
# Workflow runs are judged as well because a job can fail before GitHub
# creates it (an empty matrix), and a workflow that fails to start ends
# with no jobs at all. Neither leaves a check run, and GitHub's merge state
# ignores both: every check is green, only the run's conclusion says
# failure. Cancelled runs are skipped because when several runs start in
# the same second, `cancel-in-progress` does not always cancel the older
# one. A workflow whose every run was cancelled still blocks.
#
# The age floor covers jobs with `needs:`. GitHub creates their check run
# only when the jobs they wait on finish, so right after a push every
# check that exists can be green while later jobs have not appeared yet.

set -o errexit
set -o nounset
set -o pipefail

pr="${1:?usage: pr-ci-gate.sh <pr-number> [<expected-head-sha>]}"
expected_sha="${2:-}"
min_commit_age_min="${MIN_COMMIT_AGE_MIN:-60}"

# GitHub computes mergeStateStatus lazily: a list call usually returns
# UNKNOWN. Re-read until it settles.
for attempt in 1 2 3 4 5; do
  pr_json=$(gh pr view "${pr}" --json headRefOid,mergeStateStatus,commits,statusCheckRollup)
  state=$(jq -r '.mergeStateStatus' <<<"${pr_json}")
  if [ "${state}" != "UNKNOWN" ] || [ "${attempt}" -eq 5 ]; then
    break
  fi
  sleep 3
done

head_sha=$(jq -r '.headRefOid' <<<"${pr_json}")
if [ -n "${expected_sha}" ] && [ "${head_sha}" != "${expected_sha}" ]; then
  echo "head moved from ${expected_sha:0:7} to ${head_sha:0:7}"
  exit 1
fi

# One entry per check: the latest run per workflow + check name. A run
# that has not finished sorts last, so a pending re-run always wins over
# an older result.
checks=$(jq -c '
  [.statusCheckRollup[]
    | if .__typename == "CheckRun" then
        {key: "\(.workflowName // "")/\(.name)",
         done: (.status == "COMPLETED"),
         ok: ((.conclusion // "") | IN("SUCCESS", "SKIPPED", "NEUTRAL")),
         at: (.startedAt // ""),
         label: "\(.name)=\(if .status == "COMPLETED" then .conclusion else .status end)"}
      else
        {key: "status/\(.context)",
         done: ((.state // "") | IN("PENDING", "EXPECTED") | not),
         ok: (.state == "SUCCESS"),
         at: (.startedAt // ""),
         label: "\(.context)=\(.state)"}
      end
    | .sort = (if .done then .at else "~" end)]
  | group_by(.key)
  | map(max_by(.sort))
' <<<"${pr_json}")

# One entry per workflow, in the same shape as the checks above.
runs_json=$(gh run list --commit "${head_sha}" --limit 200 \
  --json workflowDatabaseId,workflowName,databaseId,status,conclusion)
runs=$(jq -c '
  group_by(.workflowDatabaseId)
  | map(
      (map(select(.status != "completed")) | first) as $running
      | (map(select(.conclusion != "cancelled")) | max_by(.databaseId)) as $live
      | ($running // $live // max_by(.databaseId))
      | {done: (.status == "completed"),
         ok: ((.conclusion // "") | IN("success", "skipped", "neutral")),
         label: "workflow \(.workflowName)=\(if .status == "completed" then .conclusion else .status end | ascii_upcase)"})
' <<<"${runs_json}")

failing=$(jq -r -s 'add | map(select(.done and (.ok | not)) | .label) | join(", ")' <<<"${checks}${runs}")
pending=$(jq -r -s 'add | map(select(.done | not) | .label) | join(", ")' <<<"${checks}${runs}")
total=$(jq -r 'length' <<<"${checks}")
commit_age_min=$(jq -r '(now - (.commits[-1].committedDate | fromdateiso8601)) / 60 | floor' <<<"${pr_json}")

if [ -n "${failing}" ]; then
  echo "failing: ${failing}"
  exit 1
fi
if [ -n "${pending}" ]; then
  echo "pending: ${pending}"
  exit 1
fi
if [ "${total}" -eq 0 ]; then
  echo "no checks reported"
  exit 1
fi
if [ "${commit_age_min}" -lt "${min_commit_age_min}" ]; then
  echo "head commit ${commit_age_min}m old, needs ${min_commit_age_min}m for CI to settle"
  exit 1
fi
case "${state}" in
  CLEAN|HAS_HOOKS) ;;
  *)
    echo "merge state ${state}"
    exit 1
    ;;
esac

workflows=$(jq -r 'length' <<<"${runs}")
echo "ok (${head_sha:0:7}: ${total} checks and ${workflows} workflows green, merge state ${state})"

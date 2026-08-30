---
description: Investigate cluster health via the cluster-radar agent
argument-hint: "[namespace or app, e.g. media or rook-ceph]"
---

# Triage

Investigate the live cluster: **$ARGUMENTS**

Delegate this to the `cluster-radar` subagent — cluster state and pod logs should not land in this
context window. Pass it the target above and ask for the standard report: symptom, evidence, cause,
proposed fix.

If no target was given, ask for a cluster-wide sweep: current `issues`, Flux Kustomizations and
HelmReleases that are not ready, recent changes, and node pressure.

When the agent reports back:

- If the cause is a repo-side problem, offer to make the manifest change it proposed.
- If the answer needs log *history* rather than current state — an error that started at some point,
  a rate that changed, something that already recovered — follow up with the `grafana-logs` agent.
- If it reports radar unreachable, tell the user Radar.app needs to be running for full diagnostics,
  and relay what the `kubectl`/`flux` fallback found.

Relay the findings — the agent's report is not shown to the user.

---
name: cloudflare
description: Cloudflare infrastructure for the juno.moe zone. Use when working with DNS records, WAF rules, Cloudflare Tunnel, Workers, or any Cloudflare API interaction via the MCP servers.
---

# Cloudflare MCP skill

Three Cloudflare MCP servers are globally installed:

| Tool | Use for |
|---|---|
| `cloudflare_docs` | Search Cloudflare product documentation (how-to, concepts, limitations) |
| `cloudflare_search` | Search the OpenAPI spec to find endpoints, parameters, and request body schemas. Writes JavaScript using `spec.paths`. |
| `cloudflare_execute` | Execute authenticated API calls against the Cloudflare API. Account ID `3863c7459ddd0b5db81aaa3ed633a911` is pre-set. |

## Workflow

Always use in this order:

1. **Docs** — understand the product (how does WAF work? what fields does a DNS record have?)
2. **Spec** — find the exact endpoint path, method, parameters, and body shape
3. **Execute** — make the API call

## Zones

The `juno.moe` zone ID is not hardcoded — resolve it at runtime:
```js
// in cloudflare_search or cloudflare_execute
const zones = spec.paths['/zones']?.get;
// or execute:
cloudflare.request({ method: "GET", path: `/zones?name=juno.moe` });
```

## WAF rules

Priority 0 = highest. Current rules (in order):

| Pri | Name | Type | Expression |
|---|---|---|---|
| 0 | Block threats | block | `(cf.threat_score gt 40)` |
| 5 | Allow only home country | block | `(ip.geoip.country ne "CZ")` |
| 10 | Block bots | block | `(cf.client.bot)` |
| 20 | Allow github webhooks | skip | `(http.request.uri.path contains "/hook") and (ip.src in {192.30.252.0/22, 185.199.108.0/22, 140.82.112.0/20, 143.55.64.0/20})` |
| 45 | Allow kromgo and konflate | skip | `((http.host wildcard "kromgo.juno.moe*") or (http.host eq "konflate.juno.moe")) and (ip.geoip.country eq "US")` |

Notes:
- Rule 20 replaces the old `/hook OR /api/` — do NOT open `/api/` to everyone
- Rule 10 uses `cf.client.bot` (verified bots flag), not `Known Bots equals true` (deprecated)
- GitHub webhook IP source: `https://api.github.com/meta` → `hooks`
- Rules effective only when DNS records are Proxied (orange cloud)

## Tunnel

- `external.juno.moe` routes through Cloudflare Tunnel (cloudflared)
- DNS records for tunnel endpoints must be Proxied (orange cloud)
- Tunnel config lives in the cluster (check `kubernetes/apps/system-upgrade/cloudflare-tunnel/` or `bootstrap/`)

## DNS

- Proxied records (orange cloud): tunnel endpoints, public web services
- DNS-only (grey cloud): internal services, cluster VIPs

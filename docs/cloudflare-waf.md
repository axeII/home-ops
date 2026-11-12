# Cloudflare WAF rules

Required WAF rules for the `juno.moe` zone (effective only when DNS records are Proxied/orange-cloud — required for `external.juno.moe` to route through the Cloudflare Tunnel):

| # | Rule name | Priority | Expression | Action |
|---|---|---|---|---|
| 1 | Block threats | 0 | `(cf.threat_score gt 40)` | Block |
| 2 | Allow github webhooks | 20 | `(http.request.uri.path contains "/hook") and (ip.src in {192.30.252.0/22, 185.199.108.0/22, 140.82.112.0/20, 143.55.64.0/20})` | Skip |
| 3 | Block bots | 10 | `(cf.client.bot)` | Block |
| 4 | Allow kromgo and konflate | 45 | `((http.host wildcard "kromgo.juno.moe*") or (http.host eq "konflate.juno.moe")) and (ip.geoip.country eq "US")` | Skip |
| 5 | Allow only home country | 5 | `(ip.geoip.country ne "CZ") and not (http.host eq "redlib.juno.moe" and ip.geoip.country in {"DE" "AT"})` | Block |
| 6 | Challenge redlib from DE and AT | last | `(http.host eq "redlib.juno.moe" and ip.geoip.country in {"DE" "AT"} and http.request.uri.path ne "/healthz")` | Managed Challenge |

- **Rule 2** replaces the previous broad `/hook OR /api/` rule — `/api/` is no longer opened to everyone; GitHub Actions reaches konflate `/api/` via Rule 4 (host + US country).
- **Rule 3** uses Cloudflare's `cf.client.bot` field (verified bots flag) — more reliable than the previous `Known Bots equals true`.
- **Rule 5** lets Germany and Austria reach `redlib.juno.moe` only, because the work VPN exits there. Every other hostname stays CZ-only.
- **Rule 6** makes those DE and AT visitors pass a Managed Challenge once, so scrapers in those countries cannot spend redlib's Reddit quota. Its position relative to the other rules does not matter.
- **GitHub webhook IPs** are published at `https://api.github.com/meta` under `hooks`. Update Rule 2's IP list when GitHub announces new ranges.

#!/usr/bin/env python3
"""Local proxy that adds Basic Auth to Grafana Cloud Prometheus.

Usage:
    PROM_USER=... PROM_TOKEN=... PROM_URL=... scripts/metrics-proxy.py
    just metrics-proxy
"""

import base64
import http.server
import os
import urllib.error
import urllib.request

USER = os.environ.get("PROM_USER") or ""
TOKEN = os.environ.get("PROM_TOKEN") or ""
URL = os.environ.get("PROM_URL", "").rstrip("/push")

if not USER or not TOKEN or not URL:
    print("Set PROM_USER, PROM_TOKEN, and PROM_URL environment variables")
    exit(1)


class Proxy(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self._proxy("GET")

    def do_POST(self):
        self._proxy("POST")

    def _proxy(self, method):
        body = None
        length = int(self.headers.get("Content-Length", 0))
        if method == "POST" and length > 0:
            body = self.rfile.read(length)

        headers = {k: v for k, v in self.headers.items()}
        headers.pop("Host", None)

        req = urllib.request.Request(
            f"{URL}{self.path}", method=method, headers=headers, data=body
        )
        auth = base64.b64encode(f"{USER}:{TOKEN}".encode()).decode()
        req.add_header("Authorization", f"Basic {auth}")

        try:
            resp = urllib.request.urlopen(req)
            self.send_response(resp.status)
            for k, v in resp.headers.items():
                if k.lower() not in ("transfer-encoding", "content-encoding"):
                    self.send_header(k, v)
            self.end_headers()
            self.wfile.write(resp.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.end_headers()
            self.wfile.write(e.read())


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8428"))
    print(f"Proxying http://localhost:{port} -> {URL}")
    http.server.HTTPServer(("127.0.0.1", port), Proxy).serve_forever()

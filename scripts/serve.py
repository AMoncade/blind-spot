"""Serve the repo on 127.0.0.1:34896 for the Studio loader (CLAUDE.md, "Studio"). Read only, no cache.
34893-34894 belong to Break a Gem, 34895 to Roll an Anomaly, 34890-34892 and the Rojo ports 34872-34877 to other projects.

    py scripts/serve.py
"""

import http.server
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PORT = 34896


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()

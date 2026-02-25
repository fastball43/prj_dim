#!/usr/bin/env python3
"""
Dev server that adds Cross-Origin-Isolation headers for SQLite WASM support.
Usage: python3 serve_web.py
"""
import os
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler

PORT = 8181

class COIHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, fmt, *args):
        pass  # suppress per-request logs

if __name__ == "__main__":
    web_dir = os.path.join(os.path.dirname(__file__), "build", "web")
    os.chdir(web_dir)
    server = HTTPServer(("localhost", PORT), COIHandler)
    print(f"Serving at http://localhost:{PORT}")
    print("Press Ctrl+C to stop.")
    server.serve_forever()

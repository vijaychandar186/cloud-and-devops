#!/usr/bin/env python3
"""Simple HTTP server for Lab 14 DevOps Pipeline demo."""
import http.server
import json
import os

PORT = int(os.environ.get("PORT", 8888))

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = json.dumps({"status": "ok", "lab": "14"}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(body)
        else:
            body = b"Hello from Lab 14 DevOps Pipeline!\n"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(body)

    def log_message(self, format, *args):
        pass  # suppress request logs

if __name__ == "__main__":
    with http.server.HTTPServer(("", PORT), Handler) as httpd:
        print(f"Server running on port {PORT}")
        httpd.serve_forever()

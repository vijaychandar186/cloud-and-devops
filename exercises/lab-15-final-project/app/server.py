#!/usr/bin/env python3
"""Lab 15 Final Project — Web server."""
import http.server, json, os

PORT = int(os.environ.get("PORT", 8080))
APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")
APP_ENV = os.environ.get("APP_ENV", "local")

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = json.dumps({"status": "ok", "version": APP_VERSION, "env": APP_ENV, "lab": "15"}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(body)
        else:
            body = f"Hello from Final Project! (version={APP_VERSION}, env={APP_ENV})\n".encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(body)

    def log_message(self, format, *args):
        pass

if __name__ == "__main__":
    with http.server.HTTPServer(("", PORT), Handler) as httpd:
        print(f"Server running on port {PORT} (version={APP_VERSION}, env={APP_ENV})")
        httpd.serve_forever()

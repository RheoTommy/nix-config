# Stands in for ntfy: answers every publish and appends it to a log file, one
# JSON object per line with its topic, title and message.
import http.server
import json
import sys

port, log_path = int(sys.argv[1]), sys.argv[2]


class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode()
        # Gatus publishes JSON to the root; curl publishes plain text to the topic.
        if self.headers.get("Content-Type") == "application/json":
            sent = json.loads(body)
            entry = {key: sent.get(key) for key in ("topic", "title", "message")}
        else:
            entry = {
                "topic": self.path.lstrip("/"),
                "title": self.headers.get("Title"),
                "message": body,
            }
        with open(log_path, "a") as log:
            log.write(json.dumps(entry) + "\n")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b"{}")


http.server.HTTPServer(("127.0.0.1", port), Handler).serve_forever()

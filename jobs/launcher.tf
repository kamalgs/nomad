resource "nomad_job" "launcher" {
  jobspec = <<-EOT
    job "launcher" {
      datacenters = ["dc1"]
      type        = "service"

      group "launcher" {
        count = 1

        network {
          port "http" {
            static = 9090
          }
        }

        task "launcher" {
          driver = "raw_exec"

          config {
            command = "/usr/bin/python3"
            args    = ["local/launcher.py"]
          }

          template {
            data        = <<-SCRIPT
            #!/usr/bin/env python3
            import http.server
            import json
            import urllib.request
            import sys

            NOMAD = "http://localhost:4646"
            APPS_FILE = "/opt/nomad/launcher/apps.json"

            PAGE = """<!DOCTYPE html>
            <html>
            <head><title>Starting...</title>
            <style>
            body { font-family: system-ui, sans-serif; display: flex; justify-content: center;
                   align-items: center; height: 100vh; margin: 0; background: #f8f9fa; color: #333; }
            .spin { border: 3px solid #e0e0e0; border-top-color: #555; border-radius: 50%;
                    width: 32px; height: 32px; animation: s .8s linear infinite; margin: 0 auto 16px; }
            @keyframes s { to { transform: rotate(360deg); } }
            </style></head>
            <body>
            <div style="text-align:center">
              <div class="spin"></div>
              <p>Starting <b>__HOST__</b> &hellip;</p>
            </div>
            <script>setTimeout(function(){location.reload()},3000)</script>
            </body></html>"""

            def load_apps():
                try:
                    with open(APPS_FILE) as f:
                        return json.load(f)
                except (FileNotFoundError, json.JSONDecodeError):
                    return {}

            class H(http.server.BaseHTTPRequestHandler):
                def _handle(self):
                    host = self.headers.get("Host", "").split(":")[0]
                    apps = load_apps()
                    app = apps.get(host)
                    if not app:
                        self.send_response(404)
                        self.send_header("Content-Type", "text/plain")
                        self.end_headers()
                        self.wfile.write(b"Unknown service")
                        return
                    try:
                        req = urllib.request.Request(
                            NOMAD + "/v1/job/" + app["job"] + "/scale",
                            data=json.dumps({"Count": 1, "Target": {"Group": app["group"]}}).encode(),
                            headers={"Content-Type": "application/json"},
                            method="POST")
                        urllib.request.urlopen(req)
                    except Exception as e:
                        print("launcher: " + str(e), file=sys.stderr, flush=True)
                    self.send_response(200)
                    self.send_header("Content-Type", "text/html")
                    self.end_headers()
                    self.wfile.write(PAGE.replace("__HOST__", host).encode())

                do_GET = _handle
                do_POST = _handle
                do_PUT = _handle
                do_DELETE = _handle

                def log_message(self, *a):
                    pass

            if __name__ == "__main__":
                print("launcher: listening on :9090", flush=True)
                http.server.HTTPServer(("0.0.0.0", 9090), H).serve_forever()
            SCRIPT
            destination = "local/launcher.py"
          }

          resources {
            cpu    = 50
            memory = 64
          }
        }
      }
    }
  EOT
}

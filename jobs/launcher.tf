resource "nomad_job" "launcher" {
  jobspec = <<-EOT
    job "launcher" {
      datacenters = ["dc1"]
      type        = "service"

      group "launcher" {
        count = 1

        network {
          port "http" {
            static = ${local.ports.launcher}
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
            import subprocess
            import threading
            import time
            import urllib.request
            import sys

            NOMAD = "http://localhost:4646"
            APPS_FILE = "/opt/nomad/launcher/apps.json"
            SCALER_INTERVAL = 30

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

            class Scaler:
                def __init__(self):
                    self.last_active = {}
                    t = threading.Thread(target=self._loop, daemon=True)
                    t.start()
                    print("scaler: started (interval=%ds)" % SCALER_INTERVAL, flush=True)

                def touch(self, host):
                    self.last_active[host] = time.time()

                def _loop(self):
                    while True:
                        time.sleep(SCALER_INTERVAL)
                        try:
                            self._check()
                        except Exception as e:
                            print("scaler: error: %s" % e, flush=True)

                def _check(self):
                    apps = load_apps()
                    now = time.time()
                    for host, app in apps.items():
                        port = app.get("port")
                        timeout = app.get("idle_timeout")
                        if not port or not timeout:
                            continue
                        try:
                            self._check_app(host, app, port, timeout, now)
                        except Exception as e:
                            print("scaler: error checking %s: %s" % (host, e), flush=True)

                def _check_app(self, host, app, port, timeout, now):
                    # Check if job is running
                    job_id = app["job"]
                    try:
                        resp = urllib.request.urlopen(NOMAD + "/v1/job/" + job_id + "/summary")
                        summary = json.loads(resp.read())
                    except Exception:
                        return
                    group = app["group"]
                    gs = summary.get("Summary", {}).get(group, {})
                    if gs.get("Running", 0) == 0:
                        return

                    # Count TCP connections
                    result = subprocess.run(
                        ["ss", "-tn", "state", "established", "sport", "=", ":%d" % port],
                        capture_output=True, text=True, timeout=5)
                    if result.returncode != 0:
                        return
                    # First line is header, remaining lines are connections
                    lines = result.stdout.strip().split("\n")
                    conns = max(0, len(lines) - 1)

                    if conns > 0:
                        self.last_active[host] = now
                        return

                    last = self.last_active.get(host)
                    if last is None:
                        self.last_active[host] = now
                        return

                    if now - last < timeout:
                        return

                    # Scale to zero
                    print("scaler: scaling down %s (idle %ds)" % (host, int(now - last)), flush=True)
                    req = urllib.request.Request(
                        NOMAD + "/v1/job/" + job_id + "/scale",
                        data=json.dumps({"Count": 0, "Target": {"Group": group}}).encode(),
                        headers={"Content-Type": "application/json"},
                        method="POST")
                    urllib.request.urlopen(req)
                    self.last_active.pop(host, None)

            scaler = None

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
                    scaler.touch(host)
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
                scaler = Scaler()
                print("launcher: listening on :${local.ports.launcher}", flush=True)
                http.server.HTTPServer(("0.0.0.0", ${local.ports.launcher}), H).serve_forever()
            SCRIPT
            destination = "local/launcher.py"
          }

          resources {
            cpu    = 100
            memory = 96
          }
        }
      }
    }
  EOT
}

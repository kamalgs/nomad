resource "nomad_job" "data_refresh" {
  jobspec = <<-EOT
    job "data-refresh" {
      datacenters = ["dc1"]
      type        = "batch"

      periodic {
        crons            = ["0 2 * * *"]
        prohibit_overlap = true
        time_zone        = "Asia/Kolkata"
      }

      group "refresh" {
        count = 1

        volume "finadvisor_data" {
          type      = "host"
          source    = "finadvisor_data"
          read_only = false
        }

        task "refresh" {
          driver = "docker"

          config {
            image        = "finadvisor:local"
            force_pull   = false
            network_mode = "host"
            command      = "subprime"
            args         = ["data", "refresh"]
          }

          env {
            SUBPRIME_DATA_DIR = "/app/state/data"
          }

          volume_mount {
            volume      = "finadvisor_data"
            destination = "/app/state"
          }

          resources {
            cpu    = 500
            memory = 512
          }
        }
      }
    }
  EOT
}

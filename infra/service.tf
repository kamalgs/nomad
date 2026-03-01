resource "local_file" "nomad_service" {
  content = templatefile("${path.module}/templates/nomad.service.tftpl", {
    install_dir = var.install_dir
    config_dir  = var.config_dir
  })
  filename        = "/etc/systemd/system/nomad.service"
  file_permission = "0644"

  depends_on = [terraform_data.nomad_install]
}

resource "terraform_data" "nomad_service_start" {
  triggers_replace = [
    local_file.nomad_config.content,
    local_file.nomad_service.content,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      systemctl daemon-reload
      systemctl enable nomad
      systemctl restart nomad
    EOT
  }

  depends_on = [
    local_file.nomad_config,
    local_file.nomad_service,
  ]
}

resource "local_file" "nomad_config" {
  content = templatefile("${path.module}/templates/nomad.hcl.tftpl", {
    datacenter = var.datacenter
    data_dir   = var.data_dir
  })
  filename        = "${var.config_dir}/nomad.hcl"
  file_permission = "0644"

  depends_on = [terraform_data.nomad_install]
}

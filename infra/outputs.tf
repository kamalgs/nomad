output "nomad_address" {
  description = "Nomad API address"
  value       = "http://localhost:4646"
}

output "nomad_version" {
  description = "Installed Nomad version"
  value       = var.nomad_version
}

output "data_dir" {
  description = "Nomad data directory"
  value       = var.data_dir
}

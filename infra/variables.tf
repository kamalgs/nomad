variable "nomad_version" {
  description = "Nomad binary version to install"
  type        = string
  default     = "1.11.2"
}

variable "datacenter" {
  description = "Nomad datacenter name"
  type        = string
  default     = "dc1"
}

variable "data_dir" {
  description = "Nomad data directory"
  type        = string
  default     = "/opt/nomad/data"
}

variable "config_dir" {
  description = "Nomad configuration directory"
  type        = string
  default     = "/etc/nomad.d"
}

variable "install_dir" {
  description = "Directory for the Nomad binary"
  type        = string
  default     = "/usr/local/bin"
}

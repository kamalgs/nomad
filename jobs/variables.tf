variable "nomad_address" {
  description = "Nomad API address"
  type        = string
  default     = "http://localhost:4646"
}

variable "domain" {
  type    = string
  default = "gkamal.online"
}

variable "oauth_client_id" {
  type      = string
  sensitive = true
}

variable "oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "oauth_cookie_secret" {
  type      = string
  sensitive = true
}

variable "oauth_github_user" {
  type = string
}

variable "marimo_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "marimo_oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "openwebui_secret_key" {
  type      = string
  sensitive = true
}

variable "finadvisor_anthropic_api_key" {
  type      = string
  sensitive = true
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "smtp_host" {
  type    = string
  default = ""
}

variable "smtp_port" {
  type    = string
  default = "587"
}

variable "smtp_user" {
  type    = string
  default = ""
}

variable "smtp_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "smtp_from" {
  type    = string
  default = "noreply@finadvisor.gkamal.online"
}

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

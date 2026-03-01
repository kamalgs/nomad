terraform {
  required_version = ">= 1.5"

  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.5"
    }
  }
}

provider "nomad" {
  address = var.nomad_address
}

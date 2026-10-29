terraform {
  required_providers {
    vastdata = {
      source = "vast-data/vastdata"
      version = "2.1.1"
    }
  }
}

provider "vastdata" {
  username        = var.username
  port            = 443
  password        = var.password
  host            = var.vast_host
  skip_ssl_verify = true
}

variable "password" {
  sensitive = true
}

variable "vast_host" {
  default = "10.3.2.10"
}

variable "username" {
  default = "admin"
}


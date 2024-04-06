terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "=0.51.0" # x-release-please-version
    }
    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox.endpoint
  api_token = var.proxmox.api_token
  ssh {
    agent    = true
    username = "terraform"
  }
}


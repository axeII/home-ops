terraform {

  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.10"
    }
  }
}

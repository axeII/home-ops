terraform {

  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "0.7.0"
    }
    proxmox = {
      source = "telmate/proxmox"
      version = "2.9.5"
    }
  }
}

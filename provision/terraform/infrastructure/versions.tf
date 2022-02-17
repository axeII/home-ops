terraform {

  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "0.6.3"
    }
    proxmox = {
      source = "telmate/proxmox"
      version = "2.9.5"
    }
  }
}

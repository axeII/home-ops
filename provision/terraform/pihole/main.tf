terraform {

  cloud {
    organization = "akira128"

    workspaces {
      name = "pihole"
    }
  }

  required_providers {
    pihole = {
      source  = "ryanwholey/pihole"
      version = "0.0.12"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
  }
}

data "sops_file" "pihole_secrets" {
  source_file = "secrets.sops.yaml"
}

### DOCKER ###

provider "pihole" {
  url      = data.sops_file.pihole_secrets.data["pihole_url"]
  password = data.sops_file.pihole_secrets.data["pihole_password"]
}

resource "pihole_dns_record" "proxmox_record" {
  domain = "proxmox.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.99"
}

resource "pihole_dns_record" "proxy_record" {
  domain = "proxy.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.99"
}

resource "pihole_dns_record" "mylar_record" {
  domain = "mylar.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.101"
}

resource "pihole_dns_record" "minio_record" {
  domain = "s3.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.99"
}

resource "pihole_dns_record" "minio-console_record" {
  domain = "console.s3.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.99"
}

resource "pihole_dns_record" "pihole_dns_record2" {
  domain = "console2.pihole.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.99"
}

resource "pihole_dns_record" "status_record" {
  domain = "status.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.99"
}

resource "pihole_dns_record" "nas_record" {
  domain = "truenas.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.99"
}

resource "pihole_dns_record" "proxmoxnode1" {
  domain = "proxmox-server01.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.100"
}

resource "pihole_dns_record" "proxmoxnode2" {
  domain = "proxmox-server02.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.90"
}

resource "pihole_dns_record" "proxmoxnode3" {
  domain = "proxmox-server03.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.80"
}

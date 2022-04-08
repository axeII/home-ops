terraform {

  required_providers {
    pihole = {
      source = "ryanwholey/pihole"
      version = "0.0.11"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.6.3"
    }
  }
}

data "sops_file" "pihole_secrets" {
  source_file = "secrets.sops.yaml"
}

provider "pihole" {
  url      = data.sops_file.pihole_secrets.data["pihole_url"]
  password = data.sops_file.pihole_secrets.data["pihole_password"]
}

resource "pihole_dns_record" "radarr_record" {
  domain = "radarr.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.101"
}

resource "pihole_dns_record" "sonarr_record" {
  domain = "sonarr.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.101"
}

resource "pihole_dns_record" "sabzbd_record" {
  domain = "sabnzbd.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.101"
}

resource "pihole_dns_record" "jellyfin_record" {
  domain = "jellyfin.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.101"
}

resource "pihole_dns_record" "be_jellyfin_record" {
  domain = "backend.jellyfin.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.101"
}

resource "pihole_dns_record" "proxmox_record" {
  domain = "proxmox.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.99"
}

resource "pihole_dns_record" "proxy_record" {
  domain = "proxy.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.99"
}

resource "pihole_dns_record" "comic_record" {
  domain = "comics.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.101"
}

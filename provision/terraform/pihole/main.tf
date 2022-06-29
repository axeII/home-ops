terraform {

  required_providers {
    pihole = {
      source = "ryanwholey/pihole"
      version = "0.0.12"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
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
  ip     = "192.168.69.101"
}

resource "pihole_dns_record" "minio-console_record" {
  domain = "console.s3.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.101"
}

resource "pihole_dns_record" "pihole_dns_record2" {
  domain = "console2.pihole.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.99"
}

resource "pihole_dns_record" "status_record" {
  domain = "status.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.99"
}

### K8S ###

resource "pihole_dns_record" "k8s-0_record" {
  domain = "k8s-0"
  ip     = "192.168.69.110"
}

resource "pihole_dns_record" "k8s-1_record" {
  domain = "k8s-1"
  ip     = "192.168.69.111"
}

resource "pihole_dns_record" "k8s-2_record" {
  domain = "k8s-2"
  ip     = "192.168.69.112"
}

resource "pihole_dns_record" "k8s-3_record" {
  domain = "k8s-3"
  ip     = "192.168.69.113"
}

resource "pihole_dns_record" "k8s-4_record" {
  domain = "k8s-4"
  ip     = "192.168.69.114"
}

resource "pihole_dns_record" "k8s-5_record" {
  domain = "k8s-5"
  ip     = "192.168.69.115"
}

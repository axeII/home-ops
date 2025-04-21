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
      version = "0.2.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.2.0"
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


### K8S Node ###

resource "pihole_dns_record" "k8s0" {
  domain = "k8s-0"
  ip     = "192.168.69.110"
}

resource "pihole_dns_record" "k8s1" {
  domain = "k8s-1"
  ip     = "192.168.69.109"
}

resource "pihole_dns_record" "k8s2" {
  domain = "k8s-2"
  ip     = "192.168.69.108"
}

### K8S ###

resource "pihole_dns_record" "echo-server_moe" {
  domain = "echo-server.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "juno_moe" {
  domain = data.sops_file.pihole_secrets.data["domain"]
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "metube_moe" {
  domain = "metube.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "pihole_moe" {
  domain = "pihole.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "comics_moe" {
  domain = "comics.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "goldilocks_moe" {
  domain = "goldilocks.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "longhorn_moe" {
  domain = "longhorn.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "bazarr_moe" {
  domain = "bazarr.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "lidarr_moe" {
  domain = "lidarr.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "overseerr_moe" {
  domain = "overseerr.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "requests_moe" {
  domain = "requests.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "plex_moe" {
  domain = "plex.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "prowlarr_moe" {
  domain = "prowlarr.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "radarr_moe" {
  domain = "radarr.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "radarr_uhd_moe" {
  domain = "radarr-uhd.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "readarr_moe" {
  domain = "readarr.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "sabnzbd_moe" {
  domain = "sabnzbd.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "sonarr_moe" {
  domain = "sonarr.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "tautulli_moe" {
  domain = "tautulli.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "whisparr_moe" {
  domain = "whisparr.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "grafana_moe" {
  domain = "grafana.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "kubernetes_moe" {
  domain = "kubernetes.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "alert-manager_moe" {
  domain = "alert-manager.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "prometheus_moe" {
  domain = "prometheus.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "portainer_moe" {
  domain = "portainer.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "traefik-dashboard_moe" {
  domain = "traefik-dashboard.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "weaveops" {
  domain = "gitops.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

resource "pihole_dns_record" "wikijs" {
  domain = "info.${data.sops_file.pihole_secrets.data["domain"]}"
  ip     = "192.168.69.105"
}

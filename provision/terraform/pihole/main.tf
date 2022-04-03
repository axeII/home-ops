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

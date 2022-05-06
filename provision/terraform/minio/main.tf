terraform {

  backend "remote" {
    organization = "home"
    workspaces {
      name = "home-minio"
    }
  }

  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "1.5.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.0"
    }
  }
}

data "sops_file" "minio_secrets" {
  source_file = "secret.sops.yaml"
}

provider "minio" {
  minio_server = data.sops_file.minio_secrets.data["minio_endpoint"]
  minio_access_key = data.sops_file.minio_secrets.data["minio_root_user"]
  minio_secret_key = data.sops_file.minio_secrets.data["minio_root_password"]
  minio_ssl        = true
}

locals {
  bucket_settings = {
    "k3s"      = { versioning_enabled = false },
  }
}

resource "minio_bucket" "map" {
  for_each = local.bucket_settings

  name               = each.key
  versioning_enabled = each.value.versioning_enabled
}

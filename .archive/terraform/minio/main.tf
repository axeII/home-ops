terraform {

  # backend "remote" {
  #   organization = "home"
  #   workspaces {
  #     name = "home-minio"
  #   }
  # }

  backend "local" {}

  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "3.3.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }
}

data "sops_file" "minio_secrets" {
  source_file = "secrets.sops.yaml"
}

provider "minio" {
  minio_server = data.sops_file.minio_secrets.data["minio_endpoint"]
  minio_access_key = data.sops_file.minio_secrets.data["minio_root_user"]
  minio_secret_key = data.sops_file.minio_secrets.data["minio_root_password"]
  minio_ssl        = true
}

locals {
  bucket_settings = {
    "k3s"          = { versioning_enabled = false },
    "metrics"      = { versioning_enabled = false },
    "public"      = { versioning_enabled = false },
    "loki"      = { versioning_enabled = false },
    "thanos"      = { versioning_enabled = false },
  }
}

resource "minio_s3_bucket" "map" {
  for_each = local.bucket_settings

  bucket               = each.key
  acl                  = "public"
}

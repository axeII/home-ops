variable "subnet_numbers" {
  description = "Default resource group name that the network will be created in."
  default = {
      "k8s-0" = { ip = "110", node = "pve" }
      "k8s-1" = { ip = "111", node = "node1" }
      "k8s-2" = { ip = "112", node = "pve" }
      "k8s-3" = { ip = "113", node = "node1" }
      "k8s-4" = { ip = "114", node = "pve" }
      "k8s-5" = { ip = "115", node = "pve" }
    }
}

variable "proxmox_ip" {
    default = "192.168.69.100"
}

variable "dns_server_ip" {
    default = "192.168.69.101"
}

variable "proxmox_host" {
    default = "pve"
}

variable "template_name" {
    default = "ubuntu-2004-cloudinit-template"
}

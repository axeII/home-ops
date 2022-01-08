variable "subnet_numbers" {
  description = "Default resource group name that the network will be created in."
  default = {
      "k8s-0" = "105"
      "k8s-1" = "106"
      "k8s-2" = "107"
      "k8s-3" = "108"
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

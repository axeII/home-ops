variable "proxmox_node1" {
  default = "proxmox-server01.juno.moe"
  type    = string
}

variable "proxmox_node2" {
  default = "proxmox-server02.juno.moe"
  type    = string
}

variable "proxmox_node3" {
  default = "proxmox-server03.juno.moe"
  type    = string
}

variable "template_name" {
  default = "fedora-cloudinit-template"
  type    = string
}

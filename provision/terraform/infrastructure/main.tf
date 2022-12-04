terraform {
  cloud {
    organization = "akira128"

    workspaces {
      name = "infrastructure"
    }
  }
}

data "sops_file" "proxmox_secrets" {
  source_file = "../secret.sops.yaml"
}

provider "proxmox" {
  pm_api_url  = "https://${var.proxmox_node1}:8006/api2/json"
  pm_user     = data.sops_file.proxmox_secrets.data["pm_user"]
  pm_password = data.sops_file.proxmox_secrets.data["pm_pass1"]
  alias       = "node1"
}

provider "proxmox" {
  pm_api_url  = "https://${var.proxmox_node2}:8006/api2/json"
  pm_user     = data.sops_file.proxmox_secrets.data["pm_user"]
  pm_password = data.sops_file.proxmox_secrets.data["pm_pass2"]
  alias       = "node2"
}

provider "proxmox" {
  pm_api_url  = "https://${var.proxmox_node3}:8006/api2/json"
  pm_user     = data.sops_file.proxmox_secrets.data["pm_user"]
  pm_password = data.sops_file.proxmox_secrets.data["pm_pass3"]
  alias       = "node3"
}

resource "proxmox_vm_qemu" "k8s-0" {
  name        = "k8s-0"
  provider    = proxmox.node1
  target_node = "proxmox-node1"
  clone       = var.template_name

  agent    = 1
  onboot   = "true"
  os_type  = "cloud-init"
  cores    = 8
  sockets  = 1
  cpu      = "host"
  memory   = "28672"
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot     = 0
    size     = "180G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  # if you want two NICs, just copy this whole network section and duplicate it
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # not sure exactly what this is for. presumably something about MAC addresses and ignore network changes during the life of the VM
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  ipconfig0 = "ip=192.168.69.110/24,gw=192.168.69.1"

  # sshkeys set using variables. the variable contains the text of the key.
  sshkeys = <<EOF
  ${data.sops_file.proxmox_secrets.data["ssh_key"]}
  EOF
}

resource "proxmox_vm_qemu" "k8s-1" {
  name        = "k8s-1"
  provider    = proxmox.node2
  target_node = "proxmox-node2"
  clone       = var.template_name

  agent    = 1
  onboot   = "true"
  os_type  = "cloud-init"
  cores    = 8
  sockets  = 1
  cpu      = "host"
  memory   = "28672"
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot     = 0
    size     = "180G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  # if you want two NICs, just copy this whole network section and duplicate it
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # not sure exactly what this is for. presumably something about MAC addresses and ignore network changes during the life of the VM
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  ipconfig0 = "ip=192.168.69.109/24,gw=192.168.69.1"

  # sshkeys set using variables. the variable contains the text of the key.
  sshkeys = <<EOF
  ${data.sops_file.proxmox_secrets.data["ssh_key"]}
  EOF
}

resource "proxmox_vm_qemu" "k8s-2" {
  name        = "k8s-2"
  provider    = proxmox.node3
  target_node = "proxmox-node3"
  clone       = var.template_name

  agent    = 1
  onboot   = "true"
  os_type  = "cloud-init"
  cores    = 8
  sockets  = 1
  cpu      = "host"
  memory   = "28672"
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot     = 0
    size     = "500G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  # if you want two NICs, just copy this whole network section and duplicate it
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # not sure exactly what this is for. presumably something about MAC addresses and ignore network changes during the life of the VM
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  ipconfig0 = "ip=192.168.69.108/24,gw=192.168.69.1"

  # sshkeys set using variables. the variable contains the text of the key.
  sshkeys = <<EOF
  ${data.sops_file.proxmox_secrets.data["ssh_key"]}
  EOF
}

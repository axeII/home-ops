data "sops_file" "proxmox_secrets" {
  source_file = "../secret.sops.yaml"
}


provider "proxmox" {
  pm_api_url          = "https://${var.proxmox_ip}:8006/api2/json"
  pm_api_token_id     = data.sops_file.proxmox_secrets.data["pm_api_token_id"]
  pm_api_token_secret = data.sops_file.proxmox_secrets.data["pm_api_token_secret"]
  # leave tls_insecure set to true unless you have your proxmox SSL certificate situation fully sorted out (if you do, you will know)
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "k3s_server" {
  # count = 4 # just want 1 for now, set to 0 and apply to destroy VM

  for_each = var.subnet_numbers
  name = each.key

  # this now reaches out to the vars file. I could've also used this var above in the pm_api_url setting but wanted to spell it out up there. target_node is different than api_url. target_node is which node hosts the template and thus also which node will host the new VM. it can be different than the host you use to communicate with the API. the variable contains the contents "prox-1u"
  target_node = each.value.node

  # another variable with contents "ubuntu-2004-cloudinit-template"
  clone = var.template_name

  # basic VM settings here. agent refers to guest agent
  agent = 1
  os_type = "cloud-init"
  cores = 4
  sockets = 1
  cpu = "host"
  memory = 7168
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot = 0
    # set disk size here. leave it small for testing because expanding the disk takes time.
    size = "20G"
    type = "scsi"
    storage = "local-lvm"
    iothread = 1
  }

  # if you want two NICs, just copy this whole network section and duplicate it
  network {
    model = "virtio"
    bridge = "vmbr0"
  }

  # not sure exactly what this is for. presumably something about MAC addresses and ignore network changes during the life of the VM
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  ipconfig0 = "ip=192.168.69.${each.value.ip}/24,gw=192.168.69.1"

  # sshkeys set using variables. the variable contains the text of the key.
  sshkeys = <<EOF
  ${data.sops_file.proxmox_secrets.data["ssh_key"]}
  EOF
}

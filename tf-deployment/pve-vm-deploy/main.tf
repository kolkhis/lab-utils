terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_user             = var.pm_user
  pm_api_token_secret = var.pm_api_token_secret
  pm_api_token_id     = var.pm_api_token_id
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "test-tf-vm" {
  name        = "test-tf-vm"
  vmid        = 6000
  agent       = 1
  boot        = "order=scsi0"
  target_node = "home-pve"
  clone       = "ubuntu-22.04-template"
  disk {
    storage = "vmdata"
    size    = "16G"
    type    = "disk"
    slot    = "scsi0"
  }
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  cpu {
    cores = 1
  }
  memory = 2048
}


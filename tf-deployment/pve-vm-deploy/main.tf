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
  agent       = 1
  boot        = "order=scsi0"
  target_node = "home-pve"
  clone       = "ubuntu-22.04-template"
  disk {
    storage = "vmdata"
    size    = "16G"
    type    = "disk"
    slot    = "ide0"
  }
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  cores  = 2
  memory = 2048
}


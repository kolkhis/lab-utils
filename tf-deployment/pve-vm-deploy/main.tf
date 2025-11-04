terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_user             = var.pm_user
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "test-tf-vm" {
  name        = ""
  agent       = 1
  boot        = "order=scsi0"
  target_node = "home-pve"
  clone       = "ubuntu-22.04-template"
  storage     = "vmdata"
  cores       = 2
  memory      = 2048
}


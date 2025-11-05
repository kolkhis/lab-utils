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
  name        = "test-rocky10-cloudinit-vm"
  vmid        = 6000
  agent       = 1
  boot        = "order=scsi0,virtio0"
  target_node = "home-pve"
  clone       = "rocky-10-cloudinit-template"

  memory = 4096

  cpu {
    cores   = 1
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "vmdata"
          size    = "10G"
        }
      }
    }
    ide {
      # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
      ide0 {
        cloudinit {
          storage = "vmdata"
        }
      }
    }
  }

}


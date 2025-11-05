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
  vmid        = 7000
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

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml" # /var/lib/vz/snippets/qemu-guest-agent.yml
  ciupgrade  = true
  # nameserver = "1.1.1.1 8.8.8.8"
  # ipconfig0  = "ip=192.168.4.10/24,gw=192.168.4.1,ip6=dhcp"
  skip_ipv6  = true
  ciuser     = "luser"
  cipassword = "luser"
  sshkeys    = <<EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGjGGUL4ld+JmvbDmQFu2XZrxEQio3IN7Yhgcir377t Optiplex Homelab key
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQdazsCyvNGrXGT+zEc6l5X/JILWouFlnPchYsCeFZk kolkhis@home-pve
EOF

}


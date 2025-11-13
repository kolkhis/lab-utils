locals {
  rocky_version = 10
  target_node   = "home-pve"
  vmid_start    = 7000
  network       = "192.168.4."
  ip_start      = 200
  mem           = 2048
  cpu = {
    cores   = 1
    sockets = 1
    type    = "host"
  }
  storage = {
    pool = "vmdata"
    size = "10G"
  }
}

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
  pm_log_enable       = true
  pm_log_file         = "tf-pve-plugin.log"
  pm_debug            = true
  pm_log_levels = {
    _default = "debug"
  }
}

resource "proxmox_vm_qemu" "test-tf-vm" {
  count       = 1
  description = "Rocky ${local.rocky_version} test box ${count.index} managed by Terraform"
  name        = "test-rocky${local.rocky_version}-vm${format("%02d", count.index + 1)}"
  vmid        = local.vmid_start + count.index
  agent       = 1
  boot        = "order=scsi0"
  target_node = local.target_node
  clone       = "rocky-${local.rocky_version}-cloudinit-template"
  full_clone  = false

  memory = local.mem

  cpu {
    cores   = local.cpu.cores
    sockets = local.cpu.sockets
    type    = local.cpu.type
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  scsihw = "virtio-scsi-pci"
  bios   = "ovmf"
  efidisk {
    storage = local.storage.pool
    efitype = "4m"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = local.storage.pool
          size    = local.storage.size
        }
      }
    }
    ide {
      # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
      ide2 {
        cloudinit {
          storage = local.storage.pool
        }
      }
    }
  }

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml" # /var/lib/vz/snippets/qemu-guest-agent.yml
  ciupgrade  = true
  nameserver = "1.1.1.1 8.8.8.8"
  ipconfig0  = "ip=${local.network}${local.ip_start + count.index}/24,gw=192.168.4.1,ip6=dhcp"
  skip_ipv6  = true
  ciuser     = var.ci_user
  cipassword = var.ci_pass
  sshkeys    = <<EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGjGGUL4ld+JmvbDmQFu2XZrxEQio3IN7Yhgcir377t Optiplex Homelab key
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQdazsCyvNGrXGT+zEc6l5X/JILWouFlnPchYsCeFZk kolkhis@home-pve
EOF
}


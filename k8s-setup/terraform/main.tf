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
  pm_log_enable       = false
  pm_log_file         = "tf-pve-plugin.log"
  pm_debug            = true
  pm_log_levels = {
    _default = "debug"
  }
}

locals {
  network = "192.168.4."
  # format as "${local.network}${type.ip_start}"
  control = {
    count      = 1
    ip_start   = 150
    vmid_start = 6000
  }
  worker = {
    count      = 2
    ip_start   = local.control.ip_start + local.control.count
    vmid_start = local.control.vmid_start + local.control.count
  }
  haproxy = {
    count      = 2
    ip_start   = local.control.ip_start + local.control.count + local.worker.count
    vmid_start = local.worker.vmid_start + local.worker.count
  }

  storage = {
    pool = "vmdata"
    size = "10G"
  }
  cpu = {
    cores   = 1
    sockets = 1
    type    = "host"
  }
  mem      = 2048
  pve_node = "home-pve"
  sshkeys  = <<EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGjGGUL4ld+JmvbDmQFu2XZrxEQio3IN7Yhgcir377t Optiplex Homelab key
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQdazsCyvNGrXGT+zEc6l5X/JILWouFlnPchYsCeFZk kolkhis@home-pve
EOF
}


resource "proxmox_vm_qemu" "control_nodes" {
  count = local.control.count

  name        = format("k8s-control-node%02d", count.index + 1)
  vmid        = local.control.vmid_start + count.index
  agent       = 1
  boot        = "order=scsi0"
  target_node = local.pve_node
  clone       = "rocky-10-cloudinit-template"
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
  ipconfig0  = "ip=${local.network}${local.control.ip_start + count.index}/24,gw=192.168.4.1,ip6=dhcp"
  skip_ipv6  = true
  ciuser     = var.ci_user
  cipassword = var.ci_pass
  sshkeys    = local.sshkeys
}

resource "proxmox_vm_qemu" "worker_nodes" {
  count = local.worker.count

  name        = format("k8s-worker-node%02d", count.index + 1)
  vmid        = local.worker.vmid_start + count.index
  agent       = 1
  boot        = "order=scsi0"
  target_node = local.pve_node
  clone       = "rocky-10-cloudinit-template"
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
  ipconfig0  = "ip=${local.network}${local.worker.ip_start + count.index}/24,gw=192.168.4.1,ip6=dhcp"
  skip_ipv6  = true
  ciuser     = var.ci_user
  cipassword = var.ci_pass
  sshkeys    = local.sshkeys
}

resource "proxmox_vm_qemu" "haproxy_nodes" {
  count = local.haproxy.count

  name        = format("k8s-haproxy-node%02d", count.index + 1)
  vmid        = local.haproxy.vmid_start + count.index
  agent       = 1
  boot        = "order=scsi0"
  target_node = local.pve_node
  clone       = "rocky-10-cloudinit-template"
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
  ipconfig0  = "ip=${local.network}${local.haproxy.ip_start + count.index}/24,gw=192.168.4.1,ip6=dhcp"
  skip_ipv6  = true
  ciuser     = var.ci_user
  cipassword = var.ci_pass
  sshkeys    = local.sshkeys
}


# Terraform Config for K8s

This is a Terraform configuration for provisioning VMs to use in a Kubernetes
cluster.  

Default setup is 5 VMs total:

- 1 control node
- 2 worker nodes
- 2 load balancer nodes

Each node is provisioned with the resources defined in the `locals` block
within [`main.tf`](./main.tf).  

## Main Configuration

Set the VM specs in the `locals` block, as well as the Proxmox template/VM you
wish to use as the base template.

```hcl
  clone_template = "rocky-10-cloudinit-template"
  network        = "192.168.4."
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
your keys here
EOF
```

The IP range in the default configuration is `192.168.4.150-155`.  

The control node(s) start at 150, followed by the workers, then the load balancer
nodes.  

Changing the `local.control.ip_start` variable will shift the entire range.  




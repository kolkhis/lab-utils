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

## IPs, VMIDs, VM Names
The IP range in the default configuration is `192.168.4.150-155`.  
The control node(s) start at 150, followed by the workers, then the load balancer
nodes.  

Changing the `local.control.ip_start` variable will shift the entire range.  

The default VMID range starts at `6000` and goes up to `6004` (or higher/lower 
if `count`s are changed). VMID allocation is designed to be a contiguous set of 
numbers.  

Default VMIDs can be changed by modifying the `local.control.vmid_start` variable.  

Modifying the `count` of each will dynamically update all other relevant
variables (i.e., `ip_start`, `vmid_start`).  

The name of each the VMs will be `k8s-<type>-node<count>`. 
An exception to this convention is the load balancer nodes, which will be named
`k8s-haproxy-lb<count>`. 
Naming conventions can be changed by modifying the `name` field of each
resource.  





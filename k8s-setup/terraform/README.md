# Terraform Config for K8s

This is a Terraform configuration for provisioning VMs to use in a Kubernetes
cluster.  

Default setup is 5 VMs total:

- 1 control node
- 2 worker nodes
- 2 load balancer nodes

Each node is provisioned with the resources defined in the `locals` block
within [`main.tf`](./main.tf).  

Requires a Proxmox template to use for cloning. A template must be created from 
a VM with the desired OS and base system configuration.  

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

- `clone_template`: The name of the Proxmox template to use for cloning.
- `network`: The network on which the cluster will be operating.  

The several proceeding blocks specify the number of nodes to provision, as well as
their starting IP addresses and VMIDs. 

- `control`: These variables set the the number of control nodes, the starting
  IP address (host ID), and the starting VMID number.  
    - `count`: The number of nodes to provision.  
    - `ip_start`: The starting number for the host ID (last number of the IP
      address).  
        - In this example, since the network is set to `192.168.4.`, the
          starting IP for this node will be `192.168.4.150`.  
    - `vmid_start`: The starting number for VMID assignments.  

- `worker`: Specify the number of worker nodes to provision.  
    - `count`: The number of nodes to provision.  
    - `ip_start` and `vmid_start` are incremented from the `control` block.  
        - E.g., if the `ip_start` in the `control` block is set to `150`, and 2 control 
          nodes are created, the `ip_start` will be set to `152` for the worker nodes.

- `haproxy`: Specify the number of HAProxy nodes to provision.  
    - `count`: The number of nodes to provision.  
    - `ip_start` and `vmid_start` are also incremented from the preceding blocks.  
        - E.g., if the `ip_start` in the `control` block is set to `150`, and 2 control 
          nodes are created, the `ip_start` will be set to `152` for the worker nodes.

- `storage`: This block specifies the storage pool (`pool`) used for the
  provisioned VMs, as well as the storage size allocated to those VMs.  

- `cpu`: The number of cores, sockets, and type for the VM's CPU configuration.  
    - `type`: The CPU architecture to use for the nodes.  

- `mem`: The amount of RAM to allocate to each node.  
- `pve_node`: The name of the Proxmox node on which the VMs will be
  provisioned.  

- `sshkeys`: SSH keys to add to each node's `authorized_keys` files.  

### VM Specs

All nodes have the same specs:

- 2048 memory
- CPU specs:
    - 1 core
    - 1 socket
    - `host` type.  
- 10 GB storage (in the `vmdata` storage pool)

These can all be modified in the `locals` block. Upon modification, changes
will take effect for **all** VMs (control, worker, and loadbalancer nodes).  

The CPU type is defaulted to `host` due to Rocky Linux booting into a kernel
panic when using `x86-64-v2-AES`.  
This can easily be changed within the `local.cpu.type` variable.  

The default boot method is UEFI.  

### IPs, VMIDs, VM Names
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
`k8s-haproxy-lb<count>`. The `<count>` will be zero-padded to 2 digits (e.g.,
`01`, `02`, etc.).   
Naming conventions can be changed by modifying the `name` field of each
resource.  





# Proxmox VE

Proxmox VE (Virtual Environment) is a type 1 hypervisor. It is installed on bare
metal and is used to manage virtual machines and containers.  

---

This is a collection of scripts and playbooks I've written for Proxmox-specific tasks.  

## Scripts

### `./enable-qemu-guest-agent`
This script is used to enable the QEMU guest agent in the **VM settings**.  

This script does **not** install the `qemu-guest-agent` package that is necessary in
order for the agent to work.  

That is done with the [install_qemu_guest_agent.yml](#playbooksinstallqemuguestagentyml) Ansible playbook.  

This script leverages the `qm` tool to gather a list of VM IDs and then do a `qm set`
against that list to enable the QEMU guest agent setting.  

> **Note:** This script *must* be run from the PVE host itself, not a VM.  

### `./get-vm-ips`

This script is used to gather the IPs of all the VMs in the Proxmox environment.  

It leverages the `qm` tool in conjunction with the `qemu-guest-agent` to extract the
relevant information.  

It gathers network interface information from all guest machines, as well as their
host names as they're configured locally.  

- This script is self documenting. Run `./get-vm-ips --help` for usage.  

---

The output can be plain `.txt`, or it can be in Ansible `.ini` format.  

By default, it outputs the resulting IP list in the `<hostname> <ip>` (`.txt`) format
to `stdout`. It will output any errors to `stderr` (e.g., if a host cannot be reached
via `qm`).  

Example output (default): 
```bash
host-name 192.168.1.11
host-name 192.168.1.12
# ...etc
```

Example output (ansible):
```bash
host-name ansible_host=192.168.1.11
host-name ansible_host=192.168.1.12
# ...etc
```



> **Note:** This script *must* be run from the PVE host itself, not a VM.
> Additionally, the `qemu-guest-agent` **must** be enabled for this script to work
> properly.    

## `./check-storage`

This is a simple helper script for storage troublshooting.  
It loops over the VMs in your Proxmox node and prints out the disk that it
uses.  

I wrote this to troubleshoot a storage issue I was having. A disk in a 
non-redundant ZFS pool failed, and I had to determine what VMs were using that
disk so I could clean up and rebuild.  

Functionality is sort of equivalent to:
```bash
qm config 100 | grep -i "scsi0"
```
...but for all VMs in the node, with a little extra formatting.  

Simply invoke the script with escalated privileges.  
```bash
sudo ./check-storage
```

The output will look something like this:
```plaintext
VMID: 100 - scsi0: vmdata:vm-100-disk-0,iothread=1,size=80G
VMID: 101 - scsi0: vmdata:vm-101-disk-0,iothread=1,size=60G
VMID: 102 - scsi0: local-lvm:vm-102-disk-0,iothread=1,size=32G
```



## Playbooks

### `./playbooks/install_qemu_guest_agent.yml`

This playbook is intended to be used against virtual machines hosted by Proxmox.  

It uses Ansible's `package` module to detect the package manager, then uses the 
package manager to install the `qemu-guest-agent` package.  

Then it uses the `systemd` module to ensure the `qemu-guest-agent` systemd service is
enabled and running.  
```bash
ansible-playbook -i hosts.ini ./playbooks/install_qemu_guest_agent.yml -K
```


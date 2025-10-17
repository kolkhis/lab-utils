# RAID1 Root Filesystem Setup

> **Note:** See the full writeup of the setup process either at
> [my notes site](https://notes.kolkhis.dev/homelab/storage-rebuild/) or in
> [./writeup.md](./writeup.md).  

This script assumes that you're on Proxmox that was installed with the default
LVM setup (`pve` VG).  


The script here will attempt to:

- Take a (new) disk
- Clone the boot drive's partition table to the new disk
- Create a degraded (one disk) RAID1 array using partition 3 (root fs partition)
- Add the new RAID1 array to LVM
- Migrate the existing root filesystem over to the degraded RAID1 array
- Reboot (this will require an extra invocation afterwards)
- Confirm that the root fs is mounted from the RAID array
- Add the old boot disk's root partition to the RAID array
- Wait and verify that the RAID array is in sync




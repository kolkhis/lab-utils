# Proxmox Terraform Config

These are basic Terraform configuration templates for using Terraform with 
Proxmox VE, and a helper script for creating Cloud-Init templates.  

The `./create-template` script creates a Proxmox template using the `qm`
command-line tool, geared towards creating a Proxmox template from a Cloud-Init
image (typically `.qcow2` format).  

The `./basic-clone` directory contains a Terraform configuration for cloning a
regular Proxmox VM or template. It it not meant to be used with Cloud-Init, and 
does not contain any Cloud-Init configuration.  

The `./cloud-init` directory contains a Terraform configuration for cloning a
VM or template that is Cloud-Init ready. The VM or template should be created 
using a cloud image from the OS distributor.  

## Variables

These Terraform configurations use the following variables:  

- `pm_user`
- `pm_api_url`
- `pm_api_token_secret`
- `pm_api_token_id`

The Cloud-Init config uses an additional two variables:

- `ci_user`
- `ci_pass`

These can either be set in a `.tfvars` file (e.g., `terraform.tfvars`), or set 
as environment variables in a `.env` file (or similar) and sourced before 
running.  

### Using `.tfvars`

We could create a file called `terraform.tfvars` and set the variables in this
file.  

This would look something like this:
```hcl
pm_api_token_secret = "abc123ab-c123-abc1-23ab-c123abc123ab"
pm_user             = "terraform@pve"
pm_api_url          = "http://192.168.4.49:8006/api2/json"
pm_api_token_id     = "terraform@pve!tf-token"
```
In this config, the user is `terraform@pve`, and the token's ID is `tf-token`.  

For the Cloud-Init Terraform config, an additional two variables can be set to
define the Cloud-Init user and its password.  
```hcl
ci_user = "luser"
ci_pass = "luser"
```
These two variables default to `luser` if not defined.  

### Using Environment Variables

These can alternatively be set in an environment file. A typical convention for
this is a `.env` file.  
```bash
touch .env
vi .env
```

The variables can be set inside this file with `export`, and each variable
should be prefixed with `TF_VAR_`.  

An example `.env` file would look something like:

```bash
export TF_VAR_pm_user="terraform@pve"
export TF_VAR_pm_api_url="https://192.168.1.49:8006/api2/json"
export TF_VAR_pm_api_token_id="terraform@pve!tf-token"
export TF_VAR_pm_api_token_secret="super-secret-api-key"
# if using cloud-init
export TF_VAR_ci_user="luser"
export TF_VAR_ci_pass="luser"
```

Then, before running `terraform plan` or `terraform apply`, source the file:
```bash
source .env
terraform plan
```

## `create-template` Usage

This script is used to create a Proxmox template from a Cloud-Init ready image
(usually bundled as a `.qcow2` or `.img` file).  

For example, the default image used is the Rocky Linux 10 cloud image (`Rocky-10-GenericCloud-Base.latest.x86_64.qcow2`).  
This image is downloaded from the 
[official Rocky Linux downloads](https://dl.rockylinux.org/pub/rocky/10/images/x86_64/) 
website and placed in the `/var/lib/vz/template/qcow/` directory.  
This directory must be created first, as it's not present on a base Proxmox 
installation.  

An example snippet for downloading the image to the directory:
```bash
sudo mkdir /var/lib/vz/template/qcow
cd /var/lib/vz/template/qcow
sudo curl -LO https://dl.rockylinux.org/pub/rocky/10/images/x86_64/Rocky-10-GenericCloud-Base.latest.x86_64.qcow2
```

Then the script can be run directly (using `sudo`).  
```bash
sudo ./create-template
```

By default: 

- This creates the VM with a VMID of `100`.
- It uses the Rocky 10 image shown above.  
- The template's name is "`rocky10-cloudinit-template`".  
- It allocates 2G of memory and uses the storage pool `vmdata`.  
- It uses a single CPU core and socket.  

The VM is not converted to a template by the script. After running the script,
we must convert it to a template manually. This is so further configuration can
be done before templating the VM.  

To convert to template:
```bash
sudo qm template 100 # The VMID of the resulting VM
```

The resulting template's name, VMID, storage pool, and image file used can be 
configured by passing in arguments.  

### Accepted Options/Arguments

- `-i|--image`: The image file to use.  
    - Default: `/var/lib/vz/template/qcow/Rocky-10-GenericCloud-Base.latest.x86_64.qcow2`  
- `-v|--vmid`: The VMID of the resulting Proxmox VM template.  
    - Default: `100`  
- `-n|--name`: The name of the resulting Proxmox VM template.  
    - Default: `rocky10-cloudinit-template`  
- `-s|--storage`: The storage pool to use for the VM template.  
    - Default: `vmdata`  
- `-m|--memory`: The amount of memory to assign to the VM template.  
    - Default: `2048`  
- `-c|--cores`: Number of CPU cores to assign to the VM template.  
    - Defaut: `1`  
- `-S|--sockets`: Number of CPU sockets to assign to the VM template.  
    - Defaut: `1`  
- `-t|--cpu-type`: The CPU instruction set to assign to the VM template (as
  accepted by Proxmox).  
    - Default: `host`  


An example:
```bash
sudo ./create-template  \
    --image "/path/to/example.qcow2" \
    --name "test-proxmox-template" \
    --vmid 2000 \
    --storage "local-lvm" \
    --memory 4096 \
    --cores 2 \
    --sockets 1 \
    --cpu-type "x86-64-v2-AES"

sudo qm template 2000 # Convert VM to template
```

This will create a template using the image named `test-proxmox-template`, with
a VMID of `2000`, and it will use the image `/path/to/example.qcow2`, and the
storage pool `local-lvm` will be used.  



### Cloud Image Downloads
- [Ubuntu Cloud Image Downloads](https://cloud-images.ubuntu.com/).  

- Rocky Linux:
    - [Rocky 9 Image Downloads](https://dl.rockylinux.org/pub/rocky/9/images/x86_64/)
    - [Rocky 10 Image Downloads](https://dl.rockylinux.org/pub/rocky/10/images/x86_64/)



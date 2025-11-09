# Proxmox Terraform Config

These are basic templates for using Terraform with Proxmox VE.  

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



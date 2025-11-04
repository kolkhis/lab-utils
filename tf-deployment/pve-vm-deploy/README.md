# Proxmox Terraform Config

This Terraform config uses the following variables, which should be set in a
`.tfvars` file (e.g., `terraform.tfvars`):

- `pm_user`
- `pm_api_url`
- `pm_api_token_secret`
- `pm_api_token_id`

This would look something like this:
```hcl
pm_api_token_secret = "abc123ab-c123-abc1-23ab-c123abc123ab"
pm_user             = "terraform@pve"
pm_api_url          = "http://192.168.4.49:8006/api2/json"
pm_api_token_id     = "terraform@pve!tf-token"
```
In this config, the user is `terraform@pve`, and the token's ID is `tf-token`.  



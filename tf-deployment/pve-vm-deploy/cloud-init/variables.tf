variable "pm_api_url" {
  description = "Proxmox API endpoint"
  type        = string
  default     = "http://192.168.4.49:8006/api2/json"
}

variable "pm_user" {
  description = "Proxmox user for Terraform"
  type        = string
  default     = "terraform@pve"
}

variable "pm_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
  default     = "terraform@pve!tf-token"
}

variable "pm_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}


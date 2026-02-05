# ============================================
# Key Vault Module Variables
# ============================================

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU"
  type        = string
  default     = "standard"
}

variable "enabled_for_disk_encryption" {
  description = "Enable for disk encryption"
  type        = bool
  default     = false
}

variable "enabled_for_deployment" {
  description = "Enable for VM deployment"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Enable for ARM template deployment"
  type        = bool
  default     = false
}

variable "purge_protection_enabled" {
  description = "Enable purge protection"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention days"
  type        = number
  default     = 90
}

variable "enable_rbac_authorization" {
  description = "Use RBAC for authorization"
  type        = bool
  default     = true
}

variable "aks_kubelet_identity_id" {
  description = "AKS kubelet identity object ID"
  type        = string
  default     = null
}

variable "secrets" {
  description = "Secrets to store in Key Vault"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "enable_network_rules" {
  description = "Enable network rules"
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "Allowed subnet IDs"
  type        = list(string)
  default     = []
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "name_suffix" {
  description = "Suffix for unique naming"
  type        = string
  default     = ""
}

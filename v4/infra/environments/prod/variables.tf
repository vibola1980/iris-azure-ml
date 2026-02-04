# ============================================
# Production Environment - Variables
# ============================================

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "api_key" {
  description = "API key for authentication"
  type        = string
  sensitive   = true
}

variable "alert_email_addresses" {
  description = "Email addresses for alerts"
  type        = list(string)
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints"
  type        = bool
  default     = true
}

variable "enable_azure_ad_rbac" {
  description = "Enable Azure AD RBAC for AKS"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Azure AD group IDs for AKS admin"
  type        = list(string)
  default     = []
}

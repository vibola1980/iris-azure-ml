# ============================================
# Development Environment - Variables
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
  default     = []
}

variable "enable_databricks" {
  description = "Enable Azure Databricks workspace (false = use Community Edition)"
  type        = bool
  default     = false
}

variable "databricks_sku" {
  description = "Databricks workspace SKU (standard, premium, trial)"
  type        = string
  default     = "premium"
}

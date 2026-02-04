# ============================================
# Monitoring Module Variables
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

variable "log_analytics_sku" {
  description = "Log Analytics SKU"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_days" {
  description = "Log retention days"
  type        = number
  default     = 30
}

variable "alert_email_addresses" {
  description = "Email addresses for alerts"
  type        = list(string)
  default     = []
}

variable "enable_alerts" {
  description = "Enable metric alerts"
  type        = bool
  default     = true
}

variable "aks_cluster_id" {
  description = "AKS cluster ID for alerts"
  type        = string
  default     = null
}

variable "cpu_alert_threshold" {
  description = "CPU usage alert threshold (%)"
  type        = number
  default     = 80
}

variable "memory_alert_threshold" {
  description = "Memory usage alert threshold (%)"
  type        = number
  default     = 85
}

variable "pod_restart_threshold" {
  description = "Pod restart count threshold"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

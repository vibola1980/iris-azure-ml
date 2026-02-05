# ============================================
# AKS Module Variables
# ============================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
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

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

# Node pool configuration
variable "system_node_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "system_node_count" {
  description = "Initial node count for system pool"
  type        = number
  default     = 2
}

variable "system_node_min_count" {
  description = "Minimum node count for autoscaling"
  type        = number
  default     = 2
}

variable "system_node_max_count" {
  description = "Maximum node count for autoscaling"
  type        = number
  default     = 5
}

variable "enable_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = true
}

# ML node pool
variable "enable_ml_node_pool" {
  description = "Create dedicated ML node pool"
  type        = bool
  default     = false
}

variable "ml_node_vm_size" {
  description = "VM size for ML node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "ml_node_count" {
  description = "Initial node count for ML pool"
  type        = number
  default     = 2
}

variable "ml_node_min_count" {
  description = "Minimum ML node count"
  type        = number
  default     = 1
}

variable "ml_node_max_count" {
  description = "Maximum ML node count"
  type        = number
  default     = 5
}

variable "ml_node_taints" {
  description = "Taints for ML node pool"
  type        = list(string)
  default     = []
}

# Network
variable "subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "service_cidr" {
  description = "Kubernetes service CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "10.0.0.10"
}

# Azure AD
variable "enable_azure_ad_rbac" {
  description = "Enable Azure AD RBAC"
  type        = bool
  default     = false
}

variable "admin_group_object_ids" {
  description = "Azure AD group IDs for cluster admin"
  type        = list(string)
  default     = []
}

# Monitoring
variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
}

# ACR
variable "acr_id" {
  description = "Azure Container Registry ID for AcrPull role"
  type        = string
  default     = null
}

variable "enable_acr_integration" {
  description = "Enable ACR integration (set to true when acr_id is provided)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

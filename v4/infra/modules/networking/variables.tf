# ============================================
# Networking Module Variables
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

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "AKS subnet address prefix"
  type        = list(string)
  default     = ["10.1.0.0/20"]
}

variable "private_endpoints_subnet_address_prefix" {
  description = "Private endpoints subnet address prefix"
  type        = list(string)
  default     = ["10.1.16.0/24"]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

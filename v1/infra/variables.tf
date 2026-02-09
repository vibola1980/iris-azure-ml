variable "prefix" {
  type        = string
  description = "Short unique prefix for resource naming (e.g., irisexp123)."
}

variable "location" {
  type        = string
  description = "Azure region (e.g., eastus)."
  default     = "eastus"
}

variable "container_image" {
  type        = string
  description = "Docker image in ACR (e.g., iris-api:1.0.0, without the server URL)."
}

variable "api_key" {
  type        = string
  description = "API key to protect the prediction endpoint."
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = { project = "iris-ml" }
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID where resources will be created."
}

variable "deploy_aci" {
  type        = bool
  description = "Set to true to deploy the ACI container (requires image in ACR and model in File Share)."
  default     = false
}

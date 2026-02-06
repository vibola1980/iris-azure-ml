variable "prefix" {
  type        = string
  description = "Prefixo curto e Ãºnico (ex: irisexp123)."
}

variable "location" {
  type        = string
  description = "RegiÃ£o Azure (ex: eastus)."
  default     = "eastus"
}

variable "container_image" {
  type        = string
  description = "Imagem Docker no ACR (ex: iris-api:1.0.0, sem o servidor)."
}

variable "api_key" {
  type        = string
  description = "Chave simples para proteger o endpoint."
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = { project = "iris-ml" }
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID onde os recursos serão criados."
}


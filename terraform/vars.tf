# ---------------------------------------------------------------------------
# Autenticación Azure
# ---------------------------------------------------------------------------

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Main resource group name"
  type        = string
  default     = "rg-cp2-guiurm"
}

variable "acr_name" {
  description = "ACR name (unique, 5-50, alnum)"
  type        = string
  default     = "acrunircp2guiurm"
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Subnet CIDR"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "vm_admin_username" {
  description = "VM admin username"
  type        = string
  default     = "guiurm"
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "aks_cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "aks-cp2-guiurm"
}

variable "aks_dns_prefix" {
  description = "AKS DNS prefix"
  type        = string
  default     = "akscp2guiurm"
}

variable "aks_node_count" {
  description = "Worker node count (must be 1)"
  type        = number
  default     = 1
}

variable "aks_node_vm_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "app_name" {
  description = "The name of the application. Will be used as a prefix for all resources."
  type        = string
  nullable    = false
}

variable "location" {
  description = "The Azure region in which all resources will be created."
  type        = string
  default     = "West Europe"
}

variable "public_ip_label_prefix" {
  description = "The prefix to use for the public IP label. This is to avoid conflicts with other public IPs when the users deploy an application with the same name on the same region."
  type        = string
  default     = null
}

variable "admin_ssh_public_key" {
  description = "The public key to use for SSH access to the VM."
  type        = string
  nullable    = false
}

variable "extra_resource_tags" {
  description = "Extra tags to add to all resources. This will ease the categorization of resources in the Azure portal."
  type        = map(string)
  default     = {}
}

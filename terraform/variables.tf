variable "gcp_project" {
  description = "Google Cloud project ID"
  type        = string
}

variable "gcp_region" {
  description = "Google Cloud Region"
  type        = string
}

variable "gcp_region_zone" {
  description = "Google Cloud Region Zone"
  type        = string
}

variable "gcp_credential_file" {
  description = "Google Cloud credentials file path"
  type        = string
}


variable "eth_node_vm_machine_type" {
  description = "Machine type for the Ethereum node VM"
  type        = string
  default     = "n2-standard-4"
}

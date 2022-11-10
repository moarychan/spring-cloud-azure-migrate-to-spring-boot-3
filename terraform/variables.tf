variable "application_name" {
  type        = string
  description = "The name of your application."
  default     = "migrate-to-sca-60"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created."
  default     = "eastus"
}

variable "sample_tag_value" {
  type        = string
  description = "The value of spring-cloud-azure-migrate-to-spring-boot-3 tag."
  default     = "true"
}

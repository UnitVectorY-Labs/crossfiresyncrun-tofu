variable "name" {
  description = "The name of the database"
  type        = string
}

variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "regions" {
  description = "List of regions where resources will be created"
  type        = list(string)
}

variable "deletion_policy" {
  description = "The ID of the GCP project"
  type        = string
  default     = "ABANDON"

  validation {
    condition     = contains(["ABANDON", "DELETE"], var.deletion_policy)
    error_message = "The deletion_policy variable must be one of: ABANDON, DELETE."
  }
}

variable "name" {
  description = "The name of the database (limited to 10 characters right now, boo)"
  type        = string

  validation {
    condition     = can(regex("^[a-z](?:[-a-z0-9]{1,24}[a-z0-9])$", var.name))
    error_message = "The name must start with a lowercase letter and can contain lowercase letters, numbers, and hyphens. It must be between 2 and 24 characters long."
  }
}

variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "regions" {
  description = "List of regions where resources will be created"
  type        = list(string)
}

variable "firestore_deletion_policy" {
  description = "The deletion policy for Firestore databases"
  type        = string
  default     = "ABANDON"

  validation {
    condition     = contains(["ABANDON", "DELETE"], var.firestore_deletion_policy)
    error_message = "The firestore_deletion_policy variable must be one of: ABANDON, DELETE."
  }
}

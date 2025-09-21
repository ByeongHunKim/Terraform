# ====================================================================
# ECR Module Variables
# ====================================================================

# ====================================================================
# Required Variables
# ====================================================================
variable "repositories" {
  description = "Map of ECR repositories to create"
  type = map(object({
    # Image Configuration
    image_tag_mutability = optional(string, "MUTABLE")    # MUTABLE or IMMUTABLE
    scan_on_push        = optional(bool, true)            # Enable vulnerability scanning

    # Encryption Configuration
    encryption_type = optional(string, "AES256")          # AES256 or KMS
    kms_key_id     = optional(string, null)              # KMS key for encryption

    # Lifecycle Policy Configuration
    lifecycle_policy_enabled = optional(bool, true)      # Enable lifecycle policy
    keep_last_images        = optional(number, 30)       # Keep last N tagged images
    untagged_expire_days    = optional(number, 7)        # Delete untagged images after N days

    # Access Control
    allowed_principals = optional(list(string), [])      # IAM ARNs for repository access

    # Development Configuration
    force_delete = optional(bool, false)                 # Force delete repository (dev only)
  }))

  validation {
    condition = alltrue([
      for repo in var.repositories : contains(["MUTABLE", "IMMUTABLE"], repo.image_tag_mutability)
    ])
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }

  validation {
    condition = alltrue([
      for repo in var.repositories : contains(["AES256", "KMS"], repo.encryption_type)
    ])
    error_message = "encryption_type must be either AES256 or KMS."
  }

  validation {
    condition = alltrue([
      for repo in var.repositories : repo.keep_last_images > 0
      ])
    error_message = "keep_last_images must be greater than 0."
  }
}

variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for ECR repositories"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ====================================================================
# Optional Configuration
# ====================================================================
variable "enable_registry_scanning" {
  description = "Enable ECR registry scanning configuration"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "Registry scan type (BASIC or ENHANCED)"
  type        = string
  default     = "BASIC"

  validation {
    condition     = contains(["BASIC", "ENHANCED"], var.registry_scan_type)
    error_message = "Registry scan type must be either BASIC or ENHANCED."
  }
}

variable "registry_scan_frequency" {
  description = "Registry scan frequency (SCAN_ON_PUSH, CONTINUOUS_SCAN, MANUAL)"
  type        = string
  default     = "SCAN_ON_PUSH"

  validation {
    condition = contains(["SCAN_ON_PUSH", "CONTINUOUS_SCAN", "MANUAL"], var.registry_scan_frequency)
    error_message = "Registry scan frequency must be SCAN_ON_PUSH, CONTINUOUS_SCAN, or MANUAL."
  }
}
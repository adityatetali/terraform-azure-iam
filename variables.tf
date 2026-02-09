variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "Central US"
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use existing one"
  type        = bool
  default     = true
}

variable "enable_managed_identities" {
  description = "Whether to create user-assigned managed identities"
  type        = bool
  default     = true
}

variable "managed_identities" {
  description = "Map of user-assigned managed identities to create"
  type = map(object({
    tags = map(string)
  }))
  default = {}
}

variable "enable_custom_roles" {
  description = "Whether to create custom RBAC roles"
  type        = bool
  default     = true
}

variable "custom_roles" {
  description = "Map of custom roles to create"
  type = map(object({
    description      = string
    actions          = list(string)
    not_actions      = optional(list(string), [])
    data_actions     = optional(list(string), [])
    not_data_actions = optional(list(string), [])
  }))
  default = {}
}

variable "enable_role_assignments" {
  description = "Whether to create role assignments"
  type        = bool
  default     = true
}

variable "role_assignments" {
  description = "Map of role assignments to create. For each entry either set custom_role = true and provide role_name, or provide role_definition_id directly."
  type = map(object({
    scope              = string
    role_name          = optional(string, "")
    role_definition_id = optional(string, "")
    custom_role        = optional(bool, false)
    principal_id       = string
    principal_type     = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : (
        (v.custom_role == true && v.role_name != "") || (v.custom_role == false && v.role_definition_id != "")
      )
    ])
    error_message = "Each role assignment must either have custom_role = true with a non-empty role_name, or a non-empty role_definition_id."
  }

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : (
        v.scope != "" && v.principal_id != ""
      )
    ])
    error_message = "Each role assignment must define a non-empty 'scope' and 'principal_id'."
  }
}
variable "tags" {
  description = <<EOT
Map of tags to assign all resources.
Must contain:
- Application
- Agency
- Project_code
- Environment
- Owner
EOT
  type        = map(string)
  validation {
    condition = alltrue([
      contains(keys(var.tags), "Application"),
      contains(keys(var.tags), "Agency"),
      contains(keys(var.tags), "Project_code"),
      contains(keys(var.tags), "Environment"),
      contains(keys(var.tags), "Owner"),
    ])
    error_message = "Tags must include Application, Agency, Project_code, Environment, and Owner."
  }
}

variable "subscription_id" {
  description = "Optional subscription id to target for subscription-level operations. If null, uses current subscription."
  type        = string
  default     = null
}

variable "custom_roles_scope" {
  description = "Scope for custom role creation: 'resource_group' or 'subscription'."
  type        = string
  default     = "resource_group"

  validation {
    condition     = contains(["resource_group", "subscription"], var.custom_roles_scope)
    error_message = "custom_roles_scope must be either 'resource_group' or 'subscription'."
  }
}
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "East US"
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use existing one"
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

variable "role_assignments" {
  description = "Map of role assignments to create"
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
      for k, v in var.role_assignments : v.custom_role != null || v.role_definition_id != ""
    ])
    error_message = "Either custom_role must be true with role_name, or role_definition_id must be provided."
  }
}

variable "resource_locks" {
  description = "Map of resource locks to create"
  type = map(object({
    scope      = string
    lock_level = string
    notes      = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.resource_locks : contains(["CanNotDelete", "ReadOnly"], v.lock_level)
    ])
    error_message = "Lock level must be either 'CanNotDelete' or 'ReadOnly'."
  }
}

variable "applications" {
  description = "Map of Azure AD applications to create"
  type = map(object({
    description                   = optional(string, null)
    sign_in_audience              = optional(string, "AzureADMyOrg")
    tags                          = optional(map(string), {})
    optional_claim_name           = optional(string, null)
    optional_claim_essential      = optional(bool, false)
    optional_claim_source         = optional(string, null)
    homepage_url                  = optional(string, null)
    logout_url                    = optional(string, null)
    redirect_uris                 = optional(list(string), [])
    access_token_issuance_enabled = optional(bool, false)
    id_token_issuance_enabled     = optional(bool, false)
    graph_permissions             = optional(list(string), [])
    owners                        = optional(list(string), [])
    password_expiry               = optional(string, "8760h")
  }))
  default = {}
}

variable "create_sp_passwords" {
  description = "Whether to create passwords for service principals"
  type        = bool
  default     = false
}

variable "tags" {
  description = << EOT 
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
    condition = all([
      contains(keys(var.tags), "Application"),
      contains(keys(var.tags), "Agency"),
      contains(keys(var.tags), "Project_code"),
      contains(keys(var.tags), "Environment"),
      contains(keys(var.tags), "Owner"),
    ])
    error_message = "Tags must include Application, Agency, Project_code, Environment, and Owner."
  }
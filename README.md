# terraform-azure-iam
Module to manage Azure IAM resources (module)

## Azure IAM Module

This Terraform module manages Azure Identity and Access Management (IAM) resources, including user-assigned managed identities, custom role definitions, and role assignments.

## Features ✅

- User-assigned managed identities
- Custom role definitions
- Role assignments for principals
- Tag propagation across created resources

## Usage

```
module "iam" {
  source = "./"

  resource_group_name = "rg-iam-prod"
  location            = "East US"

  managed_identities = {
    "app-identity" = {
      tags = {
        Environment   = "Production"
        Application   = "WebApp"
        Project_code  = "PRJ001"
        Agency        = "ExampleAgency"
        Owner         = "team@example.com"
      }
    }
  }

  custom_roles = {
    "custom-reader" = {
      description = "Custom read-only role for specific resources"
      actions     = [
        "Microsoft.Storage/storageAccounts/blobServices/containers/read",
        "Microsoft.Storage/storageAccounts/blobServices/read"
      ]
    }
  }

  role_assignments = {
    "storage-reader" = {
      scope              = "/subscriptions/.../resourceGroups/rg-storage"
      custom_role        = true
      role_name          = "custom-reader"
      principal_id       = "00000000-0000-0000-0000-000000000000"
      principal_type     = "ServicePrincipal"
    }
  }

  tags = {
    Application = "WebApp"
    Agency      = "ExampleAgency"
    Project_code= "PRJ001"
    Environment = "Production"
    Owner       = "team@example.com"
  }
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region for deployment | `string` | `"East US"` | no |
| create_resource_group | Whether to create a new resource group or use existing one | `bool` | `true` | no |
| managed_identities | Map of user-assigned managed identities to create | `map(object({ tags = map(string) }))` | `{}` | no |
| custom_roles | Map of custom roles to create | `map(object({ description = string, actions = list(string) }))` | `{}` | no |
| role_assignments | Map of role assignments to create | `map(object({ scope = string, role_name = optional(string), role_definition_id = optional(string), custom_role = optional(bool), principal_id = string, principal_type = string }))` | `{}` | no |
| subscription_id | Optional subscription id to target for subscription-level operations | `string` | `null` | no |
| custom_roles_scope | Scope for custom role creation (`resource_group` or `subscription`) | `string` | `"resource_group"` | no |
| tags | Tags to apply to all resources (must include Application, Agency, Project_code, Environment, Owner) | `map(string)` | n/a | yes |

---

## Outputs

| Name | Description |
|------|-------------|
| resource_group_id | ID of the resource group |
| resource_group_name | Name of the resource group |
| managed_identity_ids | Map of managed identity IDs |
| managed_identity_client_ids | Map of managed identity client IDs |
| managed_identity_principal_ids | Map of managed identity principal IDs |
| custom_role_ids | Map of custom role IDs |
| role_assignment_ids | Map of role assignment IDs |
| subscription_id | Subscription ID used (selected or current) |
| subscription_scope | Subscription scope used |

---

## Requirements

- Terraform >= 1.5.0
- AzureRM provider >= 4.0 (4.x)

---

## Handling Existing Resources

### Resource Group Already Exists

If the resource group already exists in Azure and you want Terraform to manage it, you have two options:

#### Option 1: Use Existing Resource Group (Recommended)
Set `create_resource_group = false` in your module configuration:

```hcl
module "iam" {
  source = "./"
  
  create_resource_group = false  # Reference existing RG
  resource_group_name   = "rg-iam-prod"
  location              = "Central US"
  
  # ... rest of configuration
}
```

This tells the module to reference the existing resource group instead of attempting to create a new one.

#### Option 2: Import Existing Resource Group into State
If you want Terraform to track the existing resource group, run:

```bash
terraform import 'module.iam.azurerm_resource_group.this[0]' '/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RG_NAME>'
```

Replace `<SUBSCRIPTION_ID>` and `<RG_NAME>` with your actual subscription ID and resource group name.

---

## Troubleshooting Guide

### Role Assignment Errors

**Error: `BadRequestFormat` or `UnmatchedPrincipalType`**

This occurs when:
1. The `principal_type` doesn't match the actual Azure AD object type
2. The principal ID is incorrectly formatted

**Solution:**
- Verify the principal exists in Azure AD: `az ad user show --id <principal-id>` (for users) or `az ad sp show --id <principal-id>` (for service principals)
- Ensure `principal_type` is one of: `"User"`, `"Group"`, or `"ServicePrincipal"`
- Use the correct object ID (UUID format without hyphens or with hyphens consistently)

### Custom Role Definition Issues

**Error: `Unsupported attribute "resource_id"`**

The `azurerm_role_definition` resource uses `id` (not `resource_id`) for output. The module correctly handles this by splitting the composite ID to extract the role definition ID for assignments.

---

## Notes 💡

- Ensure tags include the required keys: `Application`, `Agency`, `Project_code`, `Environment`, `Owner`.
- Custom roles can be created at the resource group or subscription scope via `custom_roles_scope`.
- Valid values for `principal_type` are: `"User"`, `"Group"`, or `"ServicePrincipal"`. Do not use `"Member"`.
- The `principal_id` must be a valid Azure AD object ID. Use `az ad user list --query "[].id"` to find user IDs or `az ad sp list --query "[].id"` for service principals.
- When using custom roles with role assignments, the module automatically extracts the correct role definition ID from the composite format.


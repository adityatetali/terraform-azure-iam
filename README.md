# terraform-azure-iam
Repo to manage Azure IAM resources (module)

## Azure IAM Module

This Terraform module manages Azure Identity and Access Management (IAM) resources, including user-assigned managed identities, custom role definitions, and role assignments.

## Features ✅

- User-assigned managed identities
- Custom role definitions
- Role assignments for principals
- Tag propagation across created resources

## Usage

```hcl
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

## Notes 💡

- Ensure tags include the required keys: `Application`, `Agency`, `Project_code`, `Environment`, `Owner`.
- Custom roles can be created at the resource group or subscription scope via `custom_roles_scope`.


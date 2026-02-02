# terraform-azure-iam
Repo to manage azure resources 

# Azure IAM Module

This Terraform module manages Azure Identity and Access Management (IAM) resources, including managed identities, custom roles, role assignments, resource locks, and Azure AD applications.

## Features

- User-assigned managed identities
- Custom role definitions
- Role assignments for principals
- Resource locks
- Azure AD applications and service principals
- Service principal password generation

## Usage

```hcl
module "iam" {
  source = "./modules/iam"

  resource_group_name = "rg-iam-prod"
  location            = "East US"
  
  managed_identities = {
    "app-identity" = {
      tags = {
        Environment = "Production"
        Application = "WebApp"
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
      principal_id       = module.iam.managed_identity_principal_ids["app-identity"]
      principal_type     = "ServicePrincipal"
    }
  }

  applications = {
    "my-webapp" = {
      description = "Web application authentication"
      tags = {
        Environment = "Production"
      }
      graph_permissions = ["User.Read", "Mail.Read"]
    }
  }

  create_sp_passwords = true
  
  tags = {
    Environment = "Production"
    Project     = "IAM Infrastructure"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region for deployment | `string` | `"East US"` | no |
| create_resource_group | Whether to create a new resource group or use existing one | `bool` | `true` | no |
| managed_identities | Map of user-assigned managed identities to create | `map(object({ tags = map(string) }))` | `{}` | no |
| custom_roles | Map of custom roles to create | `map(object({ description = string, actions = list(string) }))` | `{}` | no |
| role_assignments | Map of role assignments to create | `map(object({ scope = string, principal_id = string, principal_type = string }))` | `{}` | no |
| resource_locks | Map of resource locks to create | `map(object({ scope = string, lock_level = string }))` | `{}` | no |
| applications | Map of Azure AD applications to create | `map(object({ description = optional(string), tags = optional(map(string)) }))` | `{}` | no |
| create_sp_passwords | Whether to create passwords for service principals | `bool` | `false` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

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
| resource_lock_ids | Map of resource lock IDs |
| application_ids | Map of Azure AD application IDs |
| application_object_ids | Map of Azure AD application object IDs |
| service_principal_object_ids | Map of Azure AD service principal object IDs |
| service_principal_passwords | Map of service principal passwords (sensitive) |

## Requirements

- Terraform >= 1.5.0
- AzureRM provider >= 4.0
- AzureAD provider for application management

## Notes

- Service principal passwords are marked as sensitive and will not appear in Terraform outputs
- Custom roles are scoped to the specified resource group
- Resource locks can be "CanNotDelete" or "ReadOnly"
- Azure AD applications require appropriate permissions in your Azure AD tenant
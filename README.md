# Terraform Azure IAM Module
## Features

Terraform module that manages Azure IAM resources with a focus on clear inputs and validation:
- Create or use an existing Resource Group
- Create user-assigned managed identities (with enable/disable toggle)
- Create custom RBAC roles at either Resource Group or Subscription scope (with enable/disable toggle)
- Assign roles to principals (users, groups, service principals, or managed identities) (with enable/disable toggle)
- Enforce consistent tagging across resources

## Requirements
- Terraform >= 1.5.0
- AzureRM provider >= 4.0, < 5.0
- Azure credentials configured (e.g., via az login, environment variables, or a service principal)

## Important: Provider Configuration

**As of version 0.2.0**, this module no longer includes its own `provider "azurerm"` block. You must configure the provider in your root module:

```hcl
provider "azurerm" {
  features {}
}
```

This change was made to support `depends_on` and `for_each` with modules, which is not allowed when a module has its own provider configuration.

## Providers
- hashicorp/azurerm >= 4.0, < 5.0

## Usage

### Example: Using the published module (from Terraform Cloud/Registry)
```hcl
terraform {
  cloud {
    organization = "adityatetaliorg"
    workspaces {
      name = "terraform-azure-iam-cli"
    }
  }
}

module "iam" {
  source                = "app.terraform.io/adityatetaliorg/iam/azure"
  version               = "0.1.7"

  # Set to false if RG exists already
  create_resource_group = false
  resource_group_name   = "rg-iam-prod"
  location              = "Central US"

  # Set to false to skip creating managed identities
  enable_managed_identities = true
  managed_identities = {
    "app-identity" = {
      tags = {
        Environment  = "Production"
        Application  = "WebApp"
        Project_code = "PRJ001"
        Agency       = "ExampleAgency"
        Owner        = "team@example.com"
      }
    }
  }

  # Set to false to skip creating custom roles
  enable_custom_roles = true
  custom_roles = {
    "custom-reader" = {
      description = "Custom read-only role for specific resources"
      actions = [
        "Microsoft.Storage/storageAccounts/blobServices/containers/read",
        "Microsoft.Storage/storageAccounts/blobServices/read"
      ]
    }
  }

  role_assignments = {
    # Assign the custom role by name at a specific scope
    "storage-reader" = {
      scope          = "/subscriptions/38fe3474-4d82-4029-a49f-ba81a9ab017b/resourceGroups/rg-iam-prod"
      custom_role    = true
      role_name      = "custom-reader"          # Must match a key in custom_roles
      principal_id   = "9e9ef130-b8b7-47ee-bfc5-9a6b19383a23"
      principal_type = "User"                   # e.g., "User", "Group", "ServicePrincipal", "MSI"
    }
  }

  tags = {
    Application  = "WebApp"
    Agency       = "ExampleAgency"
    Project_code = "PRJ001"
    Environment  = "Production"
    Owner        = "team@example.com"
  }
}
```

### Example: Assign a built-in role by ID
```hcl
module "iam" {
  source = "./" # local path to this module if used directly

  create_resource_group = true
  resource_group_name   = "rg-iam-dev"
  location              = "East US"

  managed_identities = {}
  custom_roles       = {}

  role_assignments = {
    builtin-reader = {
      scope              = "/subscriptions/<sub-id>/resourceGroups/rg-iam-dev"
      custom_role        = false
      role_definition_id = "/subscriptions/<sub-id>/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader
      principal_id       = "<principal-object-id>"
      principal_type     = "ServicePrincipal"
    }
  }

  tags = {
    Application  = "ExampleApp"
    Agency       = "ExampleAgency"
    Project_code = "PRJ002"
    Environment  = "Development"
    Owner        = "team@example.com"
  }
}
```

### Example: Disable specific features
```hcl
module "iam" {
  source                = "app.terraform.io/adityatetaliorg/iam/azure"
  version               = "0.1.7"

  create_resource_group       = false
  resource_group_name         = "rg-existing"
  location                    = "East US"

  # Disable managed identities and custom roles, only create role assignments
  enable_managed_identities   = false
  enable_custom_roles         = false
  enable_role_assignments     = true

  managed_identities = {}  # Ignored when enable_managed_identities = false
  custom_roles       = {}  # Ignored when enable_custom_roles = false

  role_assignments = {
    "builtin-contributor" = {
      scope              = "/subscriptions/<sub-id>/resourceGroups/rg-existing"
      custom_role        = false
      role_definition_id = "/subscriptions/<sub-id>/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c" # Contributor
      principal_id       = "<principal-object-id>"
      principal_type     = "ServicePrincipal"
    }
  }

  tags = {
    Application  = "ExampleApp"
    Agency       = "ExampleAgency"
    Project_code = "PRJ003"
    Environment  = "Production"
    Owner        = "team@example.com"
  }
}
```

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|----------|
| resource_group_name | string | Name of the resource group (created or referenced). | - | yes |
| location | string | Azure region for deployment. | "East US" | no |
| create_resource_group | bool | Whether to create a new resource group or use an existing one. | true | no |
| enable_managed_identities | bool | Whether to create user-assigned managed identities. | true | no |
| managed_identities | map(object) | Map of user-assigned managed identities to create. The key is the identity name; the value supplies additional tags. Tags passed here are merged with the top-level tags. | {} | no |
| enable_custom_roles | bool | Whether to create custom RBAC roles. | true | no |
| custom_roles | map(object) | Map of custom roles to create. The map key is the role name. Roles are created at the scope determined by custom_roles_scope. | {} | no |
| enable_role_assignments | bool | Whether to create role assignments. | true | no |
| role_assignments | map(object) | Map of role assignments to create. Use custom_role=true with role_name for custom roles, or role_definition_id for built-in roles. | {} | no |
| tags | map(string) | Map of tags to apply to all resources. Must include: Application, Agency, Project_code, Environment, Owner. | - | yes |
| subscription_id | string | Optional subscription id to target for subscription-level operations. If null, uses current subscription. | null | no |
| custom_roles_scope | string | Scope for custom role creation: "resource_group" or "subscription". | "resource_group" | no |

### Detailed Input Specifications

#### managed_identities
Type: `map(object({ tags = map(string) }))`

Map of user-assigned managed identities to create. The key is the identity name; the value supplies additional tags. Tags passed here are merged with the top-level tags; values in the identity-specific map override on conflict.

```hcl
managed_identities = {
  "app-identity" = {
    tags = {
      Component = "WebApp"
    }
  }
}
```

#### custom_roles
Type: `map(object({ description = string, actions = list(string), not_actions = optional(list(string), []), data_actions = optional(list(string), []), not_data_actions = optional(list(string), []) }))`

Map of custom roles to create. The map key is the role name. Roles are created at the scope determined by custom_roles_scope.

```hcl
custom_roles = {
  "custom-reader" = {
    description = "Custom read-only role"
    actions = [
      "Microsoft.Storage/storageAccounts/read"
    ]
  }
}
```

#### role_assignments
Type: `map(object({ scope = string, role_name = optional(string, ""), role_definition_id = optional(string, ""), custom_role = optional(bool, false), principal_id = string, principal_type = string }))`

Map of role assignments to create. For each entry, either:
- Set `custom_role = true` and provide `role_name` (matching a key in custom_roles), or
- Provide `role_definition_id` for a built-in role and leave `custom_role = false`.

**Validation:**
- Each assignment must have either (`custom_role = true` and `role_name != ""`) OR (`custom_role = false` and `role_definition_id != ""`).
- `scope` and `principal_id` must be non-empty.

```hcl
role_assignments = {
  "assignment-1" = {
    scope              = "/subscriptions/xxx/resourceGroups/rg"
    custom_role        = true
    role_name          = "custom-reader"
    principal_id       = "xxx"
    principal_type     = "User"
  }
}
```

## Outputs

- resource_group_id: ID of the resource group
- resource_group_name: Name of the resource group
- managed_identity_ids: Map of managed identity IDs (empty if enable_managed_identities = false)
- managed_identity_client_ids: Map of managed identity client IDs (empty if enable_managed_identities = false)
- managed_identity_principal_ids: Map of managed identity principal IDs (empty if enable_managed_identities = false)
- custom_role_ids: Map of custom role IDs (empty if enable_custom_roles = false)
- role_assignment_ids: Map of role assignment IDs (empty if enable_role_assignments = false)
- subscription_id: Subscription ID used (selected or current)
- subscription_scope: Subscription scope used

## Resource Behavior
- Resource Group: Created only when create_resource_group = true; otherwise the module reads the existing RG via data.azurerm_resource_group.
- Managed Identities: Created only when enable_managed_identities = true; set to false to skip creating managed identities. Depends on Resource Group.
- Custom Roles: Created only when enable_custom_roles = true; set to false to skip creating custom roles. Roles are created under either the RG or subscription depending on custom_roles_scope, and assignable_scopes is set to the same scope. Depends on Resource Group.
- Role Assignments: Created only when enable_role_assignments = true; set to false to skip creating role assignments. Uses role_definition_name when custom_role = true; uses role_definition_id when custom_role = false. Depends on Resource Group, Custom Roles, and Managed Identities.
- Subscription Context: subscription_id (if provided) selects a target subscription; otherwise uses the active one.

### Dependency Chain
The module automatically manages resource dependencies using `depends_on`:
1. **Resource Group** is created first (if enabled)
2. **Managed Identities** and **Custom Roles** wait for Resource Group creation
3. **Role Assignments** wait for both Custom Roles and Managed Identities

This ensures that when you assign a custom role to a managed identity, both resources already exist in Azure.

### Using depends_on with Multiple Module Calls
Since the provider block is now outside the module, you can use `depends_on` when calling this module multiple times:

```hcl
module "iam_resources" {
  source = "app.terraform.io/adityatetaliorg/iam/azure"
  # ... creates managed identities and custom roles
}

module "iam_assignments" {
  source = "app.terraform.io/adityatetaliorg/iam/azure"
  # ... creates role assignments
  depends_on = [module.iam_resources]
}
```

This pattern is useful when you need to reference outputs from one module call in another.

## Permissions
- To create custom roles at subscription scope, the caller needs appropriate permissions (e.g., Owner) at that scope.
- To create role assignments, the caller usually needs Owner or User Access Administrator on the target scope.
- To create managed identities and (optionally) resource groups, the caller needs the corresponding resource permissions at the RG scope.

## Getting Started
1. Authenticate to Azure (e.g., az login or set ARM_* env vars).
2. terraform init
3. terraform plan
4. terraform apply

## Notes
- Tag merging for managed identities is merge(var.tags, each.value.tags). Identity-level tags override top-level tags on key conflicts.
- Ensure principal_type matches AzureRM expectations (e.g., "User", "Group", "ServicePrincipal", "MSI").
- Provider version pinned to >= 4.0, < 5.0 per module constraints.

## Versioning
- Terraform >= 1.5.0
- Provider azurerm >= 4.0, < 5.0

## Terraform Cloud (TFC) Support

This module is fully compatible with Terraform Cloud (TFC).

### Quick Setup

1. **Backend Configuration** - The `backend.tf` file is pre-configured for TFC:
   ```hcl
   terraform {
     cloud {
       organization = "adityatetaliorg"
       workspaces {
         name = "terraform-azure-iam-module"
       }
     }
   }
   ```

2. **Upload Variables** - Go to TFC UI and add:
   - **Environment Variables** (mark as Sensitive):
     - `ARM_CLIENT_ID`
     - `ARM_CLIENT_SECRET`
     - `ARM_SUBSCRIPTION_ID`
     - `ARM_TENANT_ID`
   
   - **Terraform Variables**:
     - `resource_group_name`
     - `enable_managed_identities`, `enable_custom_roles`, `enable_role_assignments`
     - `managed_identities`, `custom_roles`, `role_assignments`
     - `tags`

3. **Run** - Execute via TFC UI or CLI:
   ```bash
   terraform login
   terraform init
   terraform plan
   terraform apply
   ```

### Files for TFC

- `backend.tf` - TFC backend configuration
- `terraform.tfvars.tfc` - Ready-to-use tfvars template for TFC
- `tfc-sensitive-variables.tfvars` - Template for sensitive values (do not commit)
- `TFC-SETUP.md` - Detailed TFC setup instructions

### Important Notes

- **Never commit `.tfvars` files with sensitive data** - They are excluded in `.gitignore`
- Always mark sensitive variables in TFC UI with the "Sensitive" checkbox
- Use the `examples/*.tfvars` files as templates for different scenarios

For detailed TFC setup instructions, see [TFC-SETUP.md](TFC-SETUP.md).


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.5.0"
}

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  resource_group_id = var.create_resource_group ? azurerm_resource_group.this[0].id : data.azurerm_resource_group.existing[0].id
}

resource "azurerm_user_assigned_identity" "managed_identities" {
  for_each            = var.managed_identities
  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = merge(var.tags, each.value.tags)
}

resource "azurerm_role_definition" "custom_roles" {
  for_each          = var.custom_roles
  name              = each.key
  scope             = local.resource_group_id
  description       = each.value.description
  assignable_scopes = [local.resource_group_id]

  permissions {
    actions          = each.value.actions
    not_actions      = lookup(each.value, "not_actions", [])
    data_actions     = lookup(each.value, "data_actions", [])
    not_data_actions = lookup(each.value, "not_data_actions", [])
  }
}

resource "azurerm_role_assignment" "role_assignments" {
  for_each           = var.role_assignments
  scope              = each.value.scope
  role_definition_id = each.value.custom_role ? azurerm_role_definition.custom_roles[each.value.role_name].resource_id : each.value.role_definition_id
  principal_id       = each.value.principal_id
  principal_type     = each.value.principal_type
}

resource "azurerm_management_lock" "resource_locks" {
  for_each   = var.resource_locks
  name       = each.key
  scope      = each.value.scope
  lock_level = each.value.lock_level
  notes      = lookup(each.value, "notes", null)
}

resource "azurerm_azuread_application" "applications" {
  for_each         = var.applications
  display_name     = each.key
  description      = lookup(each.value, "description", null)
  sign_in_audience = lookup(each.value, "sign_in_audience", "AzureADMyOrg")
  tags             = merge(var.tags, lookup(each.value, "tags", {}))

  optional_claims {
    id_token {
      name      = lookup(each.value, "optional_claim_name", null)
      essential = lookup(each.value, "optional_claim_essential", false)
      source    = lookup(each.value, "optional_claim_source", null)
    }
  }

  web {
    homepage_url  = lookup(each.value, "homepage_url", null)
    logout_url    = lookup(each.value, "logout_url", null)
    redirect_uris = lookup(each.value, "redirect_uris", [])
    implicit_grant {
      access_token_issuance_enabled = lookup(each.value, "access_token_issuance_enabled", false)
      id_token_issuance_enabled     = lookup(each.value, "id_token_issuance_enabled", false)
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access {
      id   = lookup(each.value, "graph_permissions", [])
      type = "Scope"
    }
  }
}

resource "azurerm_azuread_service_principal" "service_principals" {
  for_each        = var.applications
  application_id  = azurerm_azuread_application.applications[each.key].application_id
  account_enabled = true
  owners          = lookup(each.value, "owners", [])
}

resource "azurerm_azuread_service_principal_password" "sp_passwords" {
  for_each             = var.create_sp_passwords ? var.applications : {}
  service_principal_id = azurerm_azuread_service_principal.service_principals[each.key].object_id
  end_date_relative    = lookup(each.value, "password_expiry", "8760h")
}
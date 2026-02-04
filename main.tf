terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0, < 5.0"
    }
  }
}
provider "azurerm" {
  features {}
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

data "azurerm_subscription" "selected" {
  subscription_id = var.subscription_id
}

locals {
  resource_group_id  = var.create_resource_group ? azurerm_resource_group.this[0].id : data.azurerm_resource_group.existing[0].id
  subscription_id    = data.azurerm_subscription.selected.subscription_id
  subscription_scope = data.azurerm_subscription.selected.id
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
  scope             = var.custom_roles_scope == "subscription" ? local.subscription_scope : local.resource_group_id
  description       = each.value.description
  assignable_scopes = [var.custom_roles_scope == "subscription" ? local.subscription_scope : local.resource_group_id]

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
  role_definition_id = each.value.custom_role ? azurerm_role_definition.custom_roles[each.value.role_name].id : each.value.role_definition_id
  principal_id       = each.value.principal_id
  principal_type     = each.value.principal_type
}
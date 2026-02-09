output "resource_group_id" {
  description = "ID of the resource group"
  value       = local.resource_group_id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "managed_identity_ids" {
  description = "Map of managed identity IDs"
  value       = var.enable_managed_identities ? { for k, v in azurerm_user_assigned_identity.managed_identities : k => v.id } : {}
}

output "managed_identity_client_ids" {
  description = "Map of managed identity client IDs"
  value       = var.enable_managed_identities ? { for k, v in azurerm_user_assigned_identity.managed_identities : k => v.client_id } : {}
}

output "managed_identity_principal_ids" {
  description = "Map of managed identity principal IDs"
  value       = var.enable_managed_identities ? { for k, v in azurerm_user_assigned_identity.managed_identities : k => v.principal_id } : {}
}

output "custom_role_ids" {
  description = "Map of custom role IDs"
  value       = var.enable_custom_roles ? { for k, v in azurerm_role_definition.custom_roles : k => v.id } : {}
}

output "role_assignment_ids" {
  description = "Map of role assignment IDs"
  value       = var.enable_role_assignments ? { for k, v in azurerm_role_assignment.role_assignments : k => v.id } : {}
}

output "subscription_id" {
  description = "Subscription ID used (selected or current)"
  value       = local.subscription_id
}
output "subscription_scope" {
  description = "Subscription scope used"
  value       = local.subscription_scope
}
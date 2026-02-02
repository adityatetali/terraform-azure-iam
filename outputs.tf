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
  value       = { for k, v in azurerm_user_assigned_identity.managed_identities : k => v.id }
}

output "managed_identity_client_ids" {
  description = "Map of managed identity client IDs"
  value       = { for k, v in azurerm_user_assigned_identity.managed_identities : k => v.client_id }
}

output "managed_identity_principal_ids" {
  description = "Map of managed identity principal IDs"
  value       = { for k, v in azurerm_user_assigned_identity.managed_identities : k => v.principal_id }
}

output "custom_role_ids" {
  description = "Map of custom role IDs"
  value       = { for k, v in azurerm_role_definition.custom_roles : k => v.resource_id }
}

output "role_assignment_ids" {
  description = "Map of role assignment IDs"
  value       = { for k, v in azurerm_role_assignment.role_assignments : k => v.id }
}

output "resource_lock_ids" {
  description = "Map of resource lock IDs"
  value       = { for k, v in azurerm_management_lock.resource_locks : k => v.id }
}

output "application_ids" {
  description = "Map of Azure AD application IDs"
  value       = { for k, v in azurerm_azuread_application.applications : k => v.application_id }
}

output "application_object_ids" {
  description = "Map of Azure AD application object IDs"
  value       = { for k, v in azurerm_azuread_application.applications : k => v.object_id }
}

output "service_principal_object_ids" {
  description = "Map of Azure AD service principal object IDs"
  value       = { for k, v in azurerm_azuread_service_principal.service_principals : k => v.object_id }
}

output "service_principal_passwords" {
  description = "Map of service principal passwords (sensitive)"
  value       = { for k, v in azurerm_azuread_service_principal_password.sp_passwords : k => v.value }
  sensitive   = true
}
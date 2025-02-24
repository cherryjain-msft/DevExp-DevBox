targetScope = 'subscription'

@description('Roles to assign to the identity.')
param roles array

@description('Scope of the role assignment. Can be either "subscription" or "resourceGroup".')
@allowed(['subscription', 'resourceGroup', 'managementGroup', 'tenant'])
param scope string

@description('The principal ID of the identity to assign the roles to.')
param principalId string

@description('Role assignment resource.')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in roles: {
    name: guid(role, scope, principalId)
    scope: subscription()
    properties: {
      principalId: principalId
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role)
      principalType: 'ServicePrincipal'
    }
  }
]

output roleAssignments array = [
  for (role, i) in roles: {
    id: roleAssignment[i].id
    name: role
  }
]

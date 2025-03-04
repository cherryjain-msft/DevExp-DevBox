targetScope = 'subscription'

@description('Roles to assign to the identity.')
param role string

@description('The principal ID of the identity to assign the roles to.')
param principalId string

@description('Role assignment resource.')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(role, principalId)
  scope: subscription()
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role)
    principalType: 'ServicePrincipal'
  }
}

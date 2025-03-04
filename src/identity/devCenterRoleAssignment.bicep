targetScope = 'subscription'

@description('The role to assign to the identity.')
param roleName string

@description('The principal ID of the identity to assign the roles to.')
param principalId string

resource role 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roleName
  scope: subscription()
}

@description('Role assignment resource.')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(role.id, principalId)
  scope: subscription()
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role.id)
    principalType: 'ServicePrincipal'
  }
}

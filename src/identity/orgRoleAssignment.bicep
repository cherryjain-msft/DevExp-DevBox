targetScope = 'subscription'
param principalId string

param roles array

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in roles: {
    name: guid(role.id, principalId)
    scope: subscription()
    properties: {
      principalId: principalId
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role.id)
      principalType: 'Group'
    }
  }
]

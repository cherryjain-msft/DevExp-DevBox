param devCenterName string

param principalId string

param roles array

resource devcenter 'Microsoft.DevCenter/devcenters@2025-02-01' existing = {
  name: devCenterName
  scope: resourceGroup()
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in roles: {
    name: guid(role.id, principalId)
    scope: devcenter
    properties: {
      principalId: principalId
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role.id)
      principalType: 'Group'
    }
  }
]

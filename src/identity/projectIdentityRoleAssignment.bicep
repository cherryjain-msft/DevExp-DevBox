param projectName string

param principalId string

param roles array

resource project 'Microsoft.DevCenter/projects@2025-02-01' existing = {
  name: projectName
  scope: resourceGroup()
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in roles: {
    name: guid(role.id, principalId)
    scope: project
    properties: {
      principalId: principalId
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role.id)
      principalType: 'Group'
    }
  }
]

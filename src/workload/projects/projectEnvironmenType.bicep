@description('Project Name')
param projectName string

@description('Project Environments')
param environments array

@description('Project')
resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' existing = {
  name: projectName
  scope: resourceGroup()
}

@description('Project Environments')
resource projectEnvironments 'Microsoft.DevCenter/projects/environmentTypes@2024-10-01-preview' = [
  for environment in environments: {
    name: environment.name
    parent: project
    tags: environment.tags
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      displayName: environment.name
      deploymentTargetId: subscription().id
      status: 'Enabled'
      creatorRoleAssignment: {
        roles: toObject(environment.roles, role => role.id, role => role.properties)
      }
    }
  }
]

@description('Project Environments')
output projectEnvironments array = [
  for (environment,i) in environments: {
    id: projectEnvironments[i].id
    name: environment.name
  }
]

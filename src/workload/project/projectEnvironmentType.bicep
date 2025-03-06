@description('Project Name')
param projectName string

@description('Environment Configuration')
param environmentConfig ProjectEnvironmentType

type ProjectEnvironmentType = {
  name: string
  deploymentTargetId: string
}

@description('Project')
resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' existing = {
  name: projectName
}

@description('Dev Center Environments')
resource environmentType 'Microsoft.DevCenter/projects/environmentTypes@2024-10-01-preview' = {
  name: environmentConfig.name
  parent: project
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: environmentConfig.name
    deploymentTargetId: empty(environmentConfig.deploymentTargetId)
      ? subscription().id
      : environmentConfig.deploymentTargetId
    status: 'Enabled'
  }
}

@description('The name of the environment type')
output environmentTypeName string = environmentType.name

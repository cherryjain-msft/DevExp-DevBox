@description('Dev Center Name')
param projectName string

@description('Environment')
param environmentConfig ProjectEnvironMentType

type ProjectEnvironMentType = {
  name: string
  deploymentTargetId: string
}

@description('Dev Center')
resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' existing = {
  name: projectName
}

@description('Dev Center Environments')
resource environmentType 'Microsoft.DevCenter/projects/environmentTypes@2024-10-01-preview' = {
  name: environmentConfig.name
  parent: project
  properties: {
    displayName: environmentConfig.name
    deploymentTargetId: empty(environmentConfig.deploymentTargetId)
      ? subscription().id
      : environmentConfig.deploymentTargetId
    status: 'Enabled'
  }
}

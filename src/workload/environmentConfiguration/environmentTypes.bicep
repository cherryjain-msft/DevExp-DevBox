@description('DevCenter Name')
param devCenterName string

@description('Network Connections')
param environmentTypes array

@description('Dev Center')
resource devCenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' existing = {
  name: devCenterName
  scope: resourceGroup()
}

@description('Dev Center Environments')
resource devCenterEnvironments 'Microsoft.DevCenter/devcenters/environmentTypes@2024-10-01-preview' = [
  for environment in environmentTypes: {
    name: environment.name
    parent: devCenter
    tags: environment.tags
    properties: {
      displayName: environment.name
    }
  }
]

@description('Dev Center Environments')
output devCenterEnvironments array = [
  for (environment,i) in environmentTypes: {
    id: devCenterEnvironments[i].id
    name: environment.name
  }
]

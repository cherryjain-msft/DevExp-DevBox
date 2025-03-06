@description('Dev Center Name')
param devCenterName string

@description('Environment Configuration')
param environmentConfig EnvironmentType

type EnvironmentType = {
  name: string
}

@description('Dev Center')
resource devCenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' existing = {
  name: devCenterName
}

@description('Dev Center Environments')
resource environmentType 'Microsoft.DevCenter/devcenters/environmentTypes@2024-10-01-preview' = {
  name: environmentConfig.name
  parent: devCenter
  properties: {
    displayName: environmentConfig.name
  }
}

@description('The name of the Environment Type')
output environmentTypeName string = environmentType.name

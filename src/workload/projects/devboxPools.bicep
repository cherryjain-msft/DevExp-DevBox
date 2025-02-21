@description('Project name')
param projectName string

@description('Project Catalogs')
param pools array

@description('Project')
resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' existing = {
  name: projectName
  scope: resourceGroup()
}

resource devBoxPools 'Microsoft.DevCenter/projects/pools@2024-10-01-preview' = [
  for pool in pools: {
    name: pool.name
    location: resourceGroup().location
    parent: project
    tags: {
      tag1: 'value1'
      tag2: 'value2'
    }
    properties: {
      displayName: pool.name
      devBoxDefinitionName: pool.devBoxDefinitionName
      licenseType: 'Windows_Client'
      localAdministrator: 'Enabled'
      singleSignOnStatus: 'Enabled'
      networkConnectionName: pool.networkConnectionName
      virtualNetworkType: 'Unmanaged'
    }
  }
]

output devBoxPools array = [
  for (pool,i) in pools: {
    id: devBoxPools[i].id
    name: pool.name
  }
]

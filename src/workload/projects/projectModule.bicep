@description('Project name')
param name string

@description('Dev Center Id')
param devCenterId string

@description('Project Catalogs')
param catalogs array

@description('Project Roles')
param roles array

@description('Environments')
param environments array

@description('DevBox Pools')
param devBoxPools array

@description('Project Tags')
param tags object

resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' = {
  name: name
  location: resourceGroup().location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    catalogSettings: {
      catalogItemSyncTypes: [
        'ImageDefinition'
        'EnvironmentDefinition'
      ]
    }
    displayName: name
    description: name
    maxDevBoxesPerUser: 5
    devCenterId: devCenterId
  }
}

@description('Project ID')
output id string = project.id

@description('Project Name')
output name string = project.name

@description('Dev Center Projects Role Assignments')
module projectRoleAssignments '../../identity/projectRoleAssignments.bicep' = {
  name: '${project.name}-roleAssignments'
  scope: resourceGroup()
  params: {
    scope: 'resourceGroup'
    principalId: project.identity.principalId
    roles: roles
  }
}

@description('Project Catalogs')
resource catalog 'Microsoft.DevCenter/projects/catalogs@2024-10-01-preview' = [
  for catalog in catalogs: {
    name: catalog.name
    parent: project
    properties: {
      gitHub: {
        uri: catalog.uri
        branch: catalog.branch
        path: catalog.path
      }
    }
  }
]

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
  for (environment, i) in environments: {
    id: projectEnvironments[i].id
    name: environment.name
  }
]

resource devBoxPool 'Microsoft.DevCenter/projects/pools@2024-10-01-preview' = [
  for pool in devBoxPools: {
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
  for (pool, i) in devBoxPools: {
    id: devBoxPool[i].id
    name: pool.name
  }
]

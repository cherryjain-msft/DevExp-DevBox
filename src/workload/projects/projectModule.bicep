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
module projectCatalogs 'catalogs.bicep' = {
  name: '${project.name}-catalogs'
  scope: resourceGroup()
  params: {
    projectName: project.name
    catalogs: catalogs
  }
}

@description('Project Environments')
module projectEnvironments 'projectEnvironmenType.bicep' = {
  name: '${project.name}-environments'
  scope: resourceGroup()
  params: {
    environments: environments
    projectName: project.name
  }
}

@description('Project DevBox Pools')
module projectDevBoxPools 'devboxPools.bicep' = {
  name: '${project.name}-devBoxPools'
  scope: resourceGroup()
  params: {
    projectName: project.name
    pools: devBoxPools
  }
}


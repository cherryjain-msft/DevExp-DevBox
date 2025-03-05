@description('Dev Center Name')
param devCenterName string

@description('Project Name')
param name string

@description('Project Description')
param projectDescription string

@description('Project Catalogs')
param projectCatalogs object

@description('Project Environment Types')
param projectEnvironmentTypes object[]

@description('Project Pools')
param projectPools object[]

@description('Network Connection Name')
param networkConnectionName string = 'Default'

@description('Secret Identifier')
@secure()
param secretIdentifier string

@description('Key Vault Name')
param keyVaultName string

@description('Security Resouce Group Name')
param securityResourceGroupName string

@description('Tags')
param tags object

type Project = {
  name: string
  description: string
  catalogs: object
  environmentTypes: object[]
  tags: object
}

@description('Dev Center')
resource devCenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' existing = {
  name: devCenterName
}

@description('Dev Center Project')
resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' = {
  name: name
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: projectDescription
    devCenterId: devCenter.id
    displayName: name
    catalogSettings: {
      catalogItemSyncTypes: [
        'EnvironmentDefinition'
        'ImageDefinition'
      ]
    }
  }
  tags: tags
}

@description('Key Vault Access Policies')
module keyVaultAccessPolicies '../../security/keyvault-access.bicep' = {
  name: 'keyvaultAccess'
  scope: resourceGroup(securityResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    principalId: project.identity.principalId
  }
}

@description('Environment Definition Catalog')
module environmentDefinitionCatalog 'projectCatalog.bicep' = {
  name: 'catalogs-${projectCatalogs.environmentDefinition.name}'
  params: {
    projectName: project.name
    catalogConfig: projectCatalogs.environmentDefinition
    secretIdentifier: secretIdentifier
  }
}

@description('Image Definition Catalog')
module imageDefinitionCatalog 'projectCatalog.bicep' = {
  name: 'catalogs-${projectCatalogs.imageDefinition.name}'
  params: {
    projectName: project.name
    catalogConfig: projectCatalogs.imageDefinition
    secretIdentifier: secretIdentifier
  }
}

@description('Project Environment Types')
module environmentTypes 'projectEnvironmentType.bicep' = [
  for environmentType in projectEnvironmentTypes: {
    name: 'environmentTypes-${environmentType.name}'
    params: {
      projectName: project.name
      environmentConfig: environmentType
    }
  }
]

@description('Project Pools')
module pools 'newPool.bicep' = [
  for pool in projectPools: {
    name: 'pools-${pool.name}'
    params: {
      name: pool.name
      projectName: project.name
      imageDefinitionName: pool.name
      networkConnectionName: networkConnectionName
    }
  }
]

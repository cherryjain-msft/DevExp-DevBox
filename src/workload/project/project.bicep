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
param networkConnectionName string

@description('Secret Identifier')
@secure()
param secretIdentifier string

@description('Key Vault Name')
param keyVaultName string

@description('Security Resource Group Name')
param securityResourceGroupName string

@description('Tags')
param tags object

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
  name: '${project.name}-keyvaultAccess'
  scope: resourceGroup(securityResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    principalId: project.identity.principalId
  }
}

@description('Environment Definition Catalog')
module catalogs 'projectCatalog.bicep' = {
  name: 'catalogs-${project.name}'
  scope: resourceGroup()
  params: {
    projectName: project.name
    catalogConfig: projectCatalogs
    secretIdentifier: secretIdentifier
  }
  dependsOn: [
    keyVaultAccessPolicies
  ]
}

@description('Project Environment Types')
module environmentTypes 'projectEnvironmentType.bicep' = [
  for environmentType in projectEnvironmentTypes: {
    name: 'environmentType-${project.name}-${environmentType.name}'
    scope: resourceGroup()
    params: {
      projectName: project.name
      environmentConfig: environmentType
    }
    dependsOn: [
      keyVaultAccessPolicies
    ]
  }
]

@description('Project Pools')
module pools 'projectPool.bicep' = [
  for pool in projectPools: {
    name: 'pool-${project.name}-${pool.name}'
    scope: resourceGroup()
    params: {
      name: pool.name
      projectName: project.name
      catalogName: projectCatalogs.imageDefinition.name
      imageDefinitionName: pool.imageDefinitionName
      networkConnectionName: networkConnectionName
    }
    dependsOn: [
      keyVaultAccessPolicies
      catalogs
    ]
  }
]

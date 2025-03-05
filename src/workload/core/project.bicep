@description('Dev Center Name')
param devCenterName string

@description('Project Name')
param name string

@description('Project Description')
param projectDescription string

@description('Project Catalogs')
param projectCatalogs Catalog[]

@description('Project Environment Types')
param projectEnvironmentTypes ProjectEnvironmentType[]

@description('Project Pools')
param projectPools Pool[]

@description('Network Connection Name')
param networkConnectionName string = 'Default'

@description('Secret Identifier')
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
  catalogs: array
  environmentTypes: ProjectEnvironmentType[]
  tags: object
}

type Catalog = {
  name: string
  type: CatalogType
  uri: string
  branch: string
  path: string
}

type CatalogType = 'gitHub' | 'adoGit'

type ProjectEnvironmentType = {
  name: string
  deploymentTargetId: string
}

type Pool = {
  name: string
  imageDefinitionName: string
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

@description('Project Catalogs')
module catalogs 'projectCatalog.bicep' = [
  for catalog in projectCatalogs: {
    name: 'catalogs-${catalog.name}'
    params: {
      projectName: project.name
      catalogConfig: catalog
      secretIdentifier: secretIdentifier
    }
  }
]

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
      imageDefinitionName: pool.imageDefinitionName
      networkConnectionName: networkConnectionName
    }
  }
]

module newPool 'projectPool.bicep' = {
  name: 'newPool'
  params: {
    name: 'newPool'
    projectName: project.name
    devBoxDefinitionName: 'backend-Engineer'
    networkConnectionName: networkConnectionName
  }
}

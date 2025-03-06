@description('Project Name')
param projectName string

@description('Catalog Configuration')
param catalogConfig ProjectCatalog

@description('Secret Identifier')
@secure()
param secretIdentifier string

type Catalog = {
  name: string
  type: CatalogType
  uri: string
  branch: string
  path: string
}

type ProjectCatalog = {
  environmentDefinition: Catalog
  imageDefinition: Catalog
}

type CatalogType = 'gitHub' | 'adoGit'

@description('Project')
resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' existing = {
  name: projectName
}

@description('Environment Definition Catalog')
resource environmentDefinitionCatalog 'Microsoft.DevCenter/projects/catalogs@2024-10-01-preview' = {
  name: catalogConfig.environmentDefinition.name
  parent: project
  properties: {
    syncType: 'Scheduled'
    gitHub: catalogConfig.environmentDefinition.type == 'gitHub'
      ? {
          uri: catalogConfig.environmentDefinition.uri
          branch: catalogConfig.environmentDefinition.branch
          path: catalogConfig.environmentDefinition.path
          secretIdentifier: secretIdentifier
        }
      : null
    adoGit: catalogConfig.environmentDefinition.type == 'adoGit'
      ? {
          uri: catalogConfig.environmentDefinition.uri
          branch: catalogConfig.environmentDefinition.branch
          path: catalogConfig.environmentDefinition.path
          secretIdentifier: secretIdentifier
        }
      : null
  }
}

@description('Image Definition Catalog')
resource imageDefinitionCatalog 'Microsoft.DevCenter/projects/catalogs@2024-10-01-preview' = {
  name: catalogConfig.imageDefinition.name
  parent: project
  properties: {
    syncType: 'Scheduled'
    gitHub: catalogConfig.imageDefinition.type == 'gitHub'
      ? {
          uri: catalogConfig.imageDefinition.uri
          branch: catalogConfig.imageDefinition.branch
          path: catalogConfig.imageDefinition.path
          secretIdentifier: secretIdentifier
        }
      : null
    adoGit: catalogConfig.imageDefinition.type == 'adoGit'
      ? {
          uri: catalogConfig.imageDefinition.uri
          branch: catalogConfig.imageDefinition.branch
          path: catalogConfig.imageDefinition.path
          secretIdentifier: secretIdentifier
        }
      : null
  }
}

@description('The name of the environment definition catalog')
output environmentDefinitionCatalogName string = environmentDefinitionCatalog.name

@description('The name of the image definition catalog')
output imageDefinitionCatalogName string = imageDefinitionCatalog.name

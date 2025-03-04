@description('Dev Center Name')
param projectName string

@description('Catalog')
param catalogConfig ProjectCatalog

@description('Secret Identifier')
param secretIdentifier string

type ProjectCatalog = {
  type: CatalogType
  name: string
  uri: string
  branch: string
  path: string
}

type CatalogType = 'gitHub' | 'adoGit'

@description('Dev Center')
resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' existing = {
  name: projectName
}

@description('Dev Center Catalogs')
resource catalog 'Microsoft.DevCenter/projects/catalogs@2024-10-01-preview' = {
  name: catalogConfig.name
  parent: project
  properties: {
    syncType: 'Scheduled'
    gitHub: catalogConfig.type == 'gitHub'
      ? {
          uri: catalogConfig.uri
          branch: catalogConfig.branch
          path: catalogConfig.path
          secretIdentifier: secretIdentifier
        }
      : null
    adoGit: catalogConfig.type == 'adoGit'
      ? {
          uri: catalogConfig.uri
          branch: catalogConfig.branch
          path: catalogConfig.path
          secretIdentifier: secretIdentifier
        }
      : null
  }
}

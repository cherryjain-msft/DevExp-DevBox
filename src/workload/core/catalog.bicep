@description('Dev Center Name')
param devCenterName string

@description('Catalog')
param catalogConfig Catalog

@description('Secret Identifier')
param secretIdentifier string


type Catalog = {
  name: string
  type: CatalogType
  uri: string
  branch: string
  path: string
}

type CatalogType = 'gitHub' | 'adoGit'

@description('Dev Center')
resource devCenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' existing = {
  name: devCenterName
}

@description('Dev Center Catalogs')
resource catalog 'Microsoft.DevCenter/devcenters/catalogs@2024-10-01-preview' = {
  name: catalogConfig.name
  parent: devCenter
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

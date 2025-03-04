@description('Dev Center Name')
param devCenterName string

@description('Catalog')
param catalogConfig Catalog

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
  properties: catalogConfig.type == 'gitHub'
    ? {
        gitHub: {
          uri: catalogConfig.uri
          branch: catalogConfig.branch
          path: catalogConfig.path
        }
        syncType: 'Scheduled'
      }
    : {
        adoGit: {
          uri: catalogConfig.uri
          branch: catalogConfig.branch
          path: catalogConfig.path
        }
        syncType: 'Scheduled'
      }
}

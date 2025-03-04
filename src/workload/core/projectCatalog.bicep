@description('Dev Center Name')
param projectName string

@description('Catalog')
param catalogConfig ProjectCatalog

type ProjectCatalog = {
  type: string
  name: string
  uri: string
  branch: string
  path: string
}

@description('Dev Center')
resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' existing = {
  name: projectName
}

@description('Dev Center Catalogs')
resource catalog 'Microsoft.DevCenter/projects/catalogs@2024-10-01-preview' = {
  name: catalogConfig.name
  parent: project
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

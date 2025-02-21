@description('Project name')
param projectName string

@description('Project Catalogs')
param catalogs array

@description('Project')
resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' existing = {
  name: projectName
  scope: resourceGroup()
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

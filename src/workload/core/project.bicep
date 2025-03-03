@description('Dev Center Name')
param devCenterName string

@description('Project')
param projectConfig Project

type Project = {
  name: string
  description: string
  catalogs: array
  environmentTypes: array
}

@description('Dev Center')
resource devCenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' existing = {
  name: devCenterName
}

@description('Dev Center Project')
resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' = {
  name: projectConfig.name
  location: resourceGroup().location
  properties: {
    description: projectConfig.description
    devCenterId: devCenter.id
    displayName: projectConfig.name
  }
}

@description('Project Catalogs')
module catalogs 'projectCatalog.bicep' = [
  for catalog in projectConfig.catalogs: {
    name: catalog.name
    params: {
      projectName: project.name
      catalogConfig: catalog
    }
  }
]

@description('Project Environment Types')
module environmentTypes 'projectEnvironmentType.bicep' = [
  for environmentType in projectConfig.environmentTypes: {
    name: environmentType.name
    params: {
      projectName: project.name
      environmentConfig: environmentType
    }
  }
]

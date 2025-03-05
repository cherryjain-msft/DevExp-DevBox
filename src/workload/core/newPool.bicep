@description('Pool Name')
param name string

@description('Location for the deployment')
param location string = resourceGroup().location

@description('The name of the dev box definition to use for the pool')
param imageDefinitionName string

@description('The name of the network connection to use for the pool')
param networkConnectionName string

@description('The name of the project to which the pool belongs')
param projectName string

@description('Project')
resource project 'Microsoft.DevCenter/projects@2024-10-01-preview' existing = {
  name: projectName
}

@description('Dev Box Pool resource')
resource pool 'Microsoft.DevCenter/projects/pools@2024-10-01-preview' = {
  name: name
  location: location
  parent: project
  properties: {
    imageDefinitionName: imageDefinitionName
    licenseType: 'Windows_Client'
    localAdministrator: 'Enabled'
    networkConnectionName: networkConnectionName
    singleSignOnStatus: 'Enabled'
    virtualNetworkType: 'Unmanaged'
  }
}

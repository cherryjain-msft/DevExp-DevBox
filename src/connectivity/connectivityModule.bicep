targetScope = 'subscription'

@description('Location for the deployment')
param location string

@description('Deployment Environment')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('Log Analytics Workspace')
param workspaceId string

@description('Landing Zone Information')
param landingZone object

var networkSettings = environment == 'dev'
  ? loadJsonContent('../../infra/settings/connectivity/settings-dev.json')
  : loadJsonContent('../../infra/settings/connectivity/settings-prod.json')

  @description('Resource Group')
  resource vNetResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
    name: landingZone.name
    location: location
  }
  

module vnet 'vnet.bicep' = {
  name: 'vnet'
  scope:vNetResourceGroup
  params: {
    networkSettings: networkSettings
    workspaceId: workspaceId
  }
}

output virtualNetworkId string = vnet.outputs.virtualNetworkId
output virtualNetworkName string = vnet.outputs.virtualNetworkName
output networkConnections array = vnet.outputs.networkConnections

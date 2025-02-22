targetScope = 'subscription'

@description('Location for the deployment')
param location string

@description('Log Analytics Workspace')
param workspaceId string

@description('Landing Zone Information')
param landingZone object

var networkSettings = loadJsonContent('../../infra/settings/connectivity/settings.json')

@description('Resource Group')
resource vNetResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.create) {
  name: landingZone.name
  location: location
}

@description('Existing Resource Group')
resource existingVNetResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!landingZone.create) {
  name: landingZone.name
}

module vnet 'vnet.bicep' = {
  name: 'VirtualNetwork'
  scope: (landingZone.create ? vNetResourceGroup : existingVNetResourceGroup)
  params: {
    networkSettings: networkSettings
    workspaceId: workspaceId
  }
}

output connectivityResourceGroupName string = (landingZone.create
  ? vNetResourceGroup.name
  : existingVNetResourceGroup.name)
output virtualNetworkId string = vnet.outputs.virtualNetworkId
output virtualNetworkName string = vnet.outputs.virtualNetworkName
output networkConnections array = vnet.outputs.networkConnections

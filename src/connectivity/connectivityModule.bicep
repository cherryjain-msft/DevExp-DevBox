targetScope = 'subscription'

@description('Location for the deployment')
param location string

@description('Log Analytics Workspace')
param workspaceId string

@description('Landing Zone Information')
param landingZone object

param formattedDateTime string = utcNow()

var networkSettings = loadJsonContent('../../infra/settings/connectivity/settings.json')

@description('Resource Group')
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.create) {
  name: landingZone.name
  location: location
}

var vNetResourceGroupName = landingZone.create ? resourceGroup.name : landingZone.name

module virtualNetwork 'vnet.bicep' = {
  name: 'VirtualNetwork-${formattedDateTime}'
  scope: az.resourceGroup(vNetResourceGroupName)
  params: {
    networkSettings: networkSettings
    workspaceId: workspaceId
  }
}

output connectivityResourceGroupName string = (landingZone.create ? resourceGroup.name : landingZone.name)
output virtualNetworkId string = virtualNetwork.outputs.virtualNetworkId
output virtualNetworkName string = virtualNetwork.outputs.virtualNetworkName
output virtualNetworkSubnets array = virtualNetwork.outputs.virtualNetworkSubnets

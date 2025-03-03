@description('Log Analytics Workspace')
param workspaceId string

var networkSettings = loadJsonContent('../../infra/settings/connectivity/settings.json')

module virtualNetwork 'vnet.bicep' = {
  name: 'VirtualNetwork'
  scope: resourceGroup()
  params: {
    settings: networkSettings
    workspaceId: workspaceId
  }
}

output virtualNetworkName string = virtualNetwork.outputs.virtualNetworkName
output virtualNetworkSubnets array = virtualNetwork.outputs.virtualNetworkSubnets

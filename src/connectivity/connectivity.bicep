@description('Log Analytics Workspace')
param workspaceId string

var networkSettings = loadYamlContent('../../infra/settings/connectivity/newtork.yaml')

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

@description('Log Analytics Workspace ID')
param workspaceId string

@description('Network settings loaded from YAML file')
var networkSettings = loadYamlContent('../../infra/settings/connectivity/newtork.yaml')

@description('Deploy Virtual Network Module')
module virtualNetwork 'vnet.bicep' = {
  name: 'VirtualNetwork'
  scope: resourceGroup()
  params: {
    settings: networkSettings
    workspaceId: workspaceId
  }
}

@description('The name of the Virtual Network')
output virtualNetworkName string = virtualNetwork.outputs.virtualNetworkName

@description('The subnets of the Virtual Network')
output virtualNetworkSubnets array = virtualNetwork.outputs.virtualNetworkSubnets

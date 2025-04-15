@description('Log Analytics ID')
param logAnalyticsId string

@description('Network settings loaded from YAML file')
var networkSettings = loadYamlContent('../../infra/settings/connectivity/newtork.yaml')

@description('Deploy Virtual Network Module')
module virtualNetwork 'vnet.bicep' = {
  name: 'VirtualNetwork'
  scope: resourceGroup()
  params: {
    logAnalyticsId: logAnalyticsId
    settings: networkSettings
  }
}

@description('The name of the Virtual Network')
output AZURE_VIRTUAL_NETWORK_NAME string = virtualNetwork.outputs.AZURE_VIRTUAL_NETWORK_NAME

@description('The subnets of the Virtual Network')
output AZURE_VIRTUAL_NETWORK_SUBNETS array = virtualNetwork.outputs.AZURE_VIRTUAL_NETWORK_SUBNETS

@description('Log Analytics workspace resource ID for diagnostic settings')
param logAnalyticsId string

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('Environment name for resource tagging and naming')
param environmentName string = 'dev'

@description('Optional resource tags to apply')
param tags object = {}

// Corrected file path typo in 'network.yaml' (was 'newtork.yaml')
@description('Network settings loaded from YAML configuration')
var networkSettings = loadYamlContent('../../infra/settings/connectivity/network.yaml')

@description('Deploy Virtual Network and related networking components')
module virtualNetwork 'vnet.bicep' = [
  for setting in networkSettings.virtualNetworks: {
    name: 'vnet-deployment-${uniqueString(resourceGroup().id, setting.name)}'
    params: {
      logAnalyticsId: logAnalyticsId
      settings: setting
      location: location
      tags: union(tags, {
        module: 'connectivity'
        environment: environmentName
      })
    }
  }
]

@description('The names of the deployed Virtual Networks')
output AZURE_VIRTUAL_NETWORK_NAMES array = [
  for i in range(0, length(networkSettings.virtualNetworks)): virtualNetwork[i].outputs.AZURE_VIRTUAL_NETWORK_NAME
]

@description('The subnets of the deployed Virtual Networks')
output AZURE_VIRTUAL_NETWORK_SUBNETS array = [
  for i in range(0, length(networkSettings.virtualNetworks)): virtualNetwork[i].outputs.AZURE_VIRTUAL_NETWORK_SUBNETS
]

@description('The resource IDs of the deployed Virtual Networks')
output AZURE_VIRTUAL_NETWORK_IDS array = [
  for i in range(0, length(networkSettings.virtualNetworks)): virtualNetwork[i].outputs.virtualNetworkId
]

@description('The list of network types for each virtual network')
output AZURE_VIRTUAL_NETWORK_TYPES array = [
  for v in networkSettings.virtualNetworks: v.virtualNetworkType
]

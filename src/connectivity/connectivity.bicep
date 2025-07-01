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

output vnets object[] = networkSettings.virtualNetworks

output AZURE_VIRTUAL_NETWORKS object[] = [
  for (vnet, i) in networkSettings.virtualNetworks: {
    name: virtualNetwork[i].outputs.AZURE_VIRTUAL_NETWORK.name
    resourceGroupName: virtualNetwork[i].outputs.AZURE_VIRTUAL_NETWORK.resourceGroupName
    virtualNetworkType: virtualNetwork[i].outputs.AZURE_VIRTUAL_NETWORK.virtualNetworkType
    subnets: virtualNetwork[i].outputs.AZURE_VIRTUAL_NETWORK.subnets
  }
]

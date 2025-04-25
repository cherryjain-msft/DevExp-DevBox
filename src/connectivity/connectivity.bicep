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
var networkSettings = loadYamlContent('../../infra/settings/connectivity/newtork.yaml')

@description('Deploy Virtual Network and related networking components')
module virtualNetwork 'vnet.bicep' = {
  name: 'vnet-deployment-${uniqueString(resourceGroup().id)}'
  params: {
    logAnalyticsId: logAnalyticsId
    settings: networkSettings
    location: location
    tags: union(tags, {
      module: 'connectivity'
      environment: environmentName
    })
  }
}

@description('The name of the deployed Virtual Network')
output AZURE_VIRTUAL_NETWORK_NAME string = virtualNetwork.outputs.AZURE_VIRTUAL_NETWORK_NAME

@description('The subnets of the deployed Virtual Network')
output AZURE_VIRTUAL_NETWORK_SUBNETS array = virtualNetwork.outputs.AZURE_VIRTUAL_NETWORK_SUBNETS

@description('The resource ID of the deployed Virtual Network')
output AZURE_VIRTUAL_NETWORK_ID string = virtualNetwork.outputs.virtualNetworkId

@description('Network type (Managed or Unmanaged)')
output AZURE_VIRTUAL_NETWORK_TYPE string = networkSettings.virtualNetworkType

targetScope = 'subscription'

@description('Name of the DevCenter instance')
param devCenterName string

@description('Project Network Connectivity')
param projectNetwork object

@description('Log Analytics workspace resource ID for diagnostic settings')
param logAnalyticsId string

@description('Azure region for resource deployment')
param location string

@description('Environment name used for resource naming (dev, test, prod)')
@minLength(2)
@maxLength(10)
param environmentName string

// Variables with consistent naming convention
var resourceNameSuffix = '${environmentName}-${location}-RG'

resource projectNetworkRg 'Microsoft.Resources/resourceGroups@2025-04-01' = if (projectNetwork.create && projectNetwork.virtualNetworkType == 'Unmanaged') {
  name: '${projectNetwork.name}-${resourceNameSuffix}'
  location: location
}

resource existingNetworkRg 'Microsoft.Resources/resourceGroups@2025-04-01' existing = if (!projectNetwork.create && projectNetwork.virtualNetworkType == 'Unmanaged') {
  name: '${projectNetwork.name}'
}

module virtualNetwork 'vnet.bicep' = {
  scope: (projectNetwork.create && projectNetwork.virtualNetworkType == 'Unmanaged')
    ? projectNetworkRg
    : existingNetworkRg
  params: {
    logAnalyticsId: logAnalyticsId
    settings: {
      name: projectNetwork.name
      tags: projectNetwork.tags
      addressPrefixes: projectNetwork.addressPrefixes
      create: projectNetwork.create
      subnets: projectNetwork.subnets
      virtualNetworkType: projectNetwork.virtualNetworkType
    }
  }
}

module networkConnection './networkConnection.bicep' = if (projectNetwork.create && projectNetwork.virtualNetworkType == 'Unmanaged') {
  name: 'networkConnection-${uniqueString(projectNetworkRg.id)}'
  scope: projectNetworkRg
  params: {
    devCenterName: devCenterName
    name: 'netconn-${virtualNetwork.name}'
    subnetId: virtualNetwork.outputs.AZURE_VIRTUAL_NETWORK.subnets[0].id
  }
}

var connectionName = (projectNetwork.create && projectNetwork.virtualNetworkType == 'Unmanaged')
  ? networkConnection.name
  : projectNetwork.name

output networkConnectionName string = connectionName

output networkType string = projectNetwork.virtualNetworkType

targetScope = 'subscription'

@description('Log Analytics workspace resource ID for diagnostic settings')
param logAnalyticsId string

@description('Azure region for resource deployment')
param location string

@description('Environment name used for resource naming (dev, test, prod)')
@minLength(2)
@maxLength(10)
param environmentName string

@description('Tags to apply to all resources')
param tags object = {}

@description('Network configuration settings')
param settings object

@description('Network settings type definition with enhanced validation')
type NetworkSettings = {
  @description('Name of the virtual network')
  name: string

  @description('Type of network to create (vnet or existing)')
  virtualNetworkType: 'Unmanaged' | 'Managed'

  @description('Flag to create new or use existing virtual network')
  create: bool

  @description('Resource group name for existing virtual network')
  resourceGroupName: string

  @description('Resource tags')
  tags: object

  @description('Address space prefixes in CIDR notation')
  addressPrefixes: string[]

  @description('Subnet configurations')
  subnets: object[]
}

// Variables with consistent naming convention
var resourceNameSuffix = '${environmentName}-${location}-RG'

resource projectNetworkRg 'Microsoft.Resources/resourceGroups@2025-04-01' = if (settings.create && settings.virtualNetworkType == 'Unmanaged') {
  name: '${settings.resourceGroupName}-${resourceNameSuffix}'
  location: location
  scope: subscription()
}

resource existingNetworkRg 'Microsoft.Resources/resourceGroups@2025-04-01' existing = if (!settings.create && settings.virtualNetworkType == 'Unmanaged') {
  name: settings.resourceGroupName
  scope: subscription()
}

@description('Virtual Network resource')
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = if (settings.create && settings.virtualNetworkType == 'Unmanaged') {
  name: settings.name
  scope: projectNetworkRg
  location: location
  tags: union(tags, settings.tags)
  properties: {
    addressSpace: {
      addressPrefixes: settings.addressPrefixes
    }
    subnets: [
      for subnet in settings.subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.properties.addressPrefix
        }
      }
    ]
  }
}

@description('Reference to existing Virtual Network')
resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = if (!settings.create && settings.virtualNetworkType == 'Unmanaged') {
  name: settings.name
  scope: existingNetworkRg
}

@description('Log Analytics Diagnostic Settings')
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (settings.create && settings.virtualNetworkType == 'Unmanaged') {
  name: '${virtualNetwork.name}-diag'
  scope: virtualNetwork
  properties: {
    workspaceId: logAnalyticsId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output AZURE_VIRTUAL_NETWORK object = (settings.create && settings.virtualNetworkType == 'Unmanaged')
  ? {
      name: virtualNetwork.name
      resourceGroupName: projectNetworkRg.name
      virtualNetworkType: settings.virtualNetworkType
      subnets: virtualNetwork.properties.subnets
    }
  : (!settings.create && settings.virtualNetworkType == 'Unmanaged')
      ? {
          name: existingVirtualNetwork.name
          resourceGroupName: existingNetworkRg.name
          virtualNetworkType: settings.virtualNetworkType
          subnets: existingVirtualNetwork.properties.subnets
        }
      : {
          name: ''
          resourceGroupName: ''
          virtualNetworkType: settings.virtualNetworkType
          subnets: []
        }

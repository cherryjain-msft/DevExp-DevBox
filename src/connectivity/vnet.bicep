@description('Log Analytics Workspace')
param workspaceId string

@description('Network Settings')
param settings NetworkSettings

type NetworkSettings = {
  name: string
  create: bool
  tags: object
  addressPrefixes: array
  subnets: array
}

@description('Virtual Network')
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = if (settings.create) {
  name: settings.name
  location: resourceGroup().location
  tags: settings.tags
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

@description('Existing Virtual Network')
resource existingVNetRg 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: settings.name
  scope: resourceGroup()
  dependsOn: [
    virtualNetwork
  ]
}

@description('Network Diagnostic Settings')
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (settings.create) {
  name: '${virtualNetwork.name}-diagnostic'
  scope: existingVNetRg
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
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
    workspaceId: workspaceId
  }
}

@description('The ID of the Virtual Network')
output virtualNetworkId string = (settings.create) ? virtualNetwork.id : existingVNetRg.id

@description('The subnets of the Virtual Network')
output virtualNetworkSubnets array = [
  for (subnet, i) in settings.subnets: {
    id: (settings.create) ? virtualNetwork.properties.subnets[i].id : existingVNetRg.properties.subnets[i].id
    name: (settings.create) ? subnet.name : existingVNetRg.properties.subnets[i].name
  }
]

@description('The name of the Virtual Network')
output virtualNetworkName string = (settings.create) ? virtualNetwork.name : existingVNetRg.name

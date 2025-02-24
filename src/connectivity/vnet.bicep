@description('Log Analytics Workspace')
param workspaceId string

@description('Network Settings')
param networkSettings object

@description('Virtual Network')
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = if (networkSettings.create) {
  name: networkSettings.name
  location: resourceGroup().location
  tags: networkSettings.tags
  properties: {
    addressSpace: {
      addressPrefixes: networkSettings.addressPrefixes
    }
    subnets: [
      for subnet in networkSettings.subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.properties.addressPrefix
        }
      }
    ]
  }
}

resource existingVNet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = if (!networkSettings.create) {
  name: networkSettings.name
  scope: resourceGroup()
}

@description('Network Diagnostic Settings')
module vnetDiagnosticSettings '../management/diagnosticSettings.bicep'= {
  name: 'vnetDiagnosticSettings'
  params: {
    resourceType: 'vNet'
    resourceName: (networkSettings.create) ? virtualNetwork.name : existingVNet.name
    workspaceId: workspaceId
  }
} 

output virtualNetworkId string = (networkSettings.create) ? virtualNetwork.id : existingVNet.id

output virtualNetworkSubnets array = [
  for (subnet, i) in networkSettings.subnets: {
    id: (networkSettings.create) ? virtualNetwork.properties.subnets[i].id : existingVNet.properties.subnets[i].id
    name: (networkSettings.create) ? subnet.name : existingVNet.properties.subnets[i].name
  }
]

output virtualNetworkName string = (networkSettings.create) ? virtualNetwork.name : existingVNet.name

@description('Network Connections for the Virtual Network Subnets')
resource networkConnection 'Microsoft.DevCenter/networkConnections@2024-10-01-preview' = [
  for (subnet, i) in networkSettings.subnets: {
    name: subnet.name
    location: resourceGroup().location
    tags: networkSettings.tags
    properties: {
      domainJoinType: 'AzureADJoin'
      subnetId: (networkSettings.create)
        ? virtualNetwork.properties.subnets[i].id
        : existingVNet.properties.subnets[i].id
    }
  }
]

output networkConnections array = [
  for (connection, i) in networkSettings.subnets: {
    id: networkConnection[i].id
    name: networkConnection[i].name
  }
]

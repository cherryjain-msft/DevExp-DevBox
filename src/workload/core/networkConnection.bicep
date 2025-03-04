@description('Network Connection Name')
param name string

@description('DevCenter Resource')
param devCenterName string

@description('Network Connection for the Virtual Network Subnet')
param subnetId string

@description('DevCenter Resource')
resource devcenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' existing = {
  name: devCenterName
}

@description('Network Connections for the Virtual Network Subnets')
resource netConnection 'Microsoft.DevCenter/networkConnections@2024-10-01-preview' = {
  name: name
  location: resourceGroup().location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: subnetId
  }
}

@description('DevCenter Network Connection')
resource vnetAttachment 'Microsoft.DevCenter/devcenters/attachednetworks@2024-10-01-preview' = {
  name: name
  parent: devcenter
  properties: {
    networkConnectionId: netConnection.id
  }
}

output vnetAttachmentName string = vnetAttachment.name

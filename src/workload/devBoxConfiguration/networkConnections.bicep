@description('DevCenter Name')
param devCenterName string

@description('Network Connections')
param networkConnections array

@description('Dev Center')
resource devCenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' existing = {
  name: devCenterName
  scope: resourceGroup()
}

@description('Deploys Network Connections for the Dev Center')
resource vNetAttachment 'Microsoft.DevCenter/devcenters/attachednetworks@2024-10-01-preview' = [
  for connection in networkConnections: {
    name: connection.name
    parent: devCenter
    properties: {
      networkConnectionId: connection.id
    }
  }
]

@description('Network Connections')
output vNetAttachments array = [
  for (connection,i) in networkConnections: {
    id: vNetAttachment[i].id
    name: connection.name
  }
]

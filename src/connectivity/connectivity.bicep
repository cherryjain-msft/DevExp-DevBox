
targetScope = 'subscription'

@description('Landing Zone Connectivity')
param landingZone LandingZone

@description('Location for the deployment')
param location string

@description('Log Analytics Workspace')
param workspaceId string

type LandingZone = {
  name: string
  create: bool
  tags: object
}

var networkSettings = loadYamlContent('../../infra/settings/connectivity/newtork.yaml')

@description('Connectivity Resource Group')
resource connectivityRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.create) {
  name: landingZone.name
  location: location
  tags: landingZone.tags
}

var rgName = landingZone.create ? connectivityRg.name : landingZone.name

module virtualNetwork 'vnet.bicep' = {
  name: 'VirtualNetwork'
  scope: resourceGroup(rgName)
  params: {
    settings: networkSettings
    workspaceId: workspaceId
  }
}

output virtualNetworkName string = virtualNetwork.outputs.virtualNetworkName
output virtualNetworkSubnets array = virtualNetwork.outputs.virtualNetworkSubnets

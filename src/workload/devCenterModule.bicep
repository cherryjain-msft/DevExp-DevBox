targetScope = 'subscription'

@description('Deployment Environment')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('Location')
param location string

@description('Landing Zone settings')
param landingZone object

@description('Network Connections settings')
param networkConnections array

@description('Workspace ID')
param workspaceId string

@description('Dev Center settings')
var settings = environment == 'dev'
  ? loadJsonContent('../../infra/settings/workload/settings.dev.json')
  : loadJsonContent('../../infra/settings/workload/settings.prod.json')

@description('Workload Resource Group')
resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.create) {
  name: landingZone.name
  location: location
}

output workloadResourceGroupName string = (landingZone.create) ? workloadResourceGroup.name : landingZone.name

@description('Dev Center Resource')
module devCenter './devCenter.bicep' = {
  name: 'devCenter'
  scope: resourceGroup(workloadResourceGroupName)
  params: {
    settings: settings
    networkConnections: networkConnections
    workspaceId: workspaceId
  }
}

output devCenterId string = devCenter.outputs.devCenterId
output devCenterName string = devCenter.outputs.devCenterName

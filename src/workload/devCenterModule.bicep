targetScope = 'subscription'

@description('Location')
param location string

@description('Landing Zone settings')
param landingZone object

@description('Network Connections settings')
param networkConnections array

@description('Workspace ID')
param workspaceId string

@description('Dev Center settings')
var settings = loadJsonContent('../../infra/settings/workload/settings.json')

@description('Workload Resource Group')
resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.create) {
  name: landingZone.name
  location: location
}

@description('Existing Workload Resource Group')
resource existingWorkloadResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!landingZone.create) {
  name: landingZone.name
}

var resourceGroupName = landingZone.create ? workloadResourceGroup.name : landingZone.name

@description('Dev Center Resource')
module devCenter './devCenter.bicep' = {
  name: 'devCenter'
  scope: resourceGroup(resourceGroupName)
  params: {
    settings: settings
    networkConnections: networkConnections
    workspaceId: workspaceId
  }
}

output devCenterId string = devCenter.outputs.devCenterId
output devCenterName string = devCenter.outputs.devCenterName
output workloadResourceGroupName string = (landingZone.create
  ? workloadResourceGroup.name
  : existingWorkloadResourceGroup.name)

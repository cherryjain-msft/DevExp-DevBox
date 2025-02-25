targetScope = 'subscription'

@description('Location')
param location string

@description('Landing Zone settings')
param landingZone object

@description('Network Connections settings')
param sbunets array

@description('Workspace ID')
param workspaceId string

@description('Dev Center Compute Gallery')
param computeGalleryName string

@description('Compute Gallery ID')
param computeGalleryId string

param formattedDateTime string = utcNow()

@description('Dev Center settings')
var settings = loadJsonContent('../../infra/settings/workload/settings.json')

@description('Workload Resource Group')
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.create) {
  name: landingZone.name
  location: location
  tags: landingZone.tags
}

var resourceGroupName = landingZone.create ? resourceGroup.name : landingZone.name

@description('Dev Center Resource')
module devCenter './devCenter.bicep' = {
  name: 'devCenter-${formattedDateTime}'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    settings: settings
    subnets: sbunets
    workspaceId: workspaceId
    computeGalleryName: computeGalleryName
    computeGalleryId: computeGalleryId
  }
}

output devCenterId string = devCenter.outputs.devCenterId
output devCenterName string = devCenter.outputs.devCenterName
output workloadResourceGroupName string = (landingZone.create ? resourceGroup.name : landingZone.name)

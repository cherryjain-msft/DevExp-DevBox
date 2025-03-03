@description('Network Connections settings')
param sbunets array

@description('Workspace ID')
param workspaceId string

@description('Dev Center Compute Gallery')
param computeGalleryName string

@description('Compute Gallery ID')
param computeGalleryId string

@description('Dev Center settings')
var settings = loadJsonContent('../../infra/settings/workload/settings.json')

@description('Dev Center Resource')
module devCenter './devCenter.bicep' = {
  name: 'devCenter'
  scope: resourceGroup()
  params: {
    settings: settings
    subnets: sbunets
    workspaceId: workspaceId
    computeGalleryName: computeGalleryName
    computeGalleryId: computeGalleryId
  }
}

output devCenterName string = devCenter.outputs.devCenterName
output devCenterprojects array = devCenter.outputs.devCenterprojects

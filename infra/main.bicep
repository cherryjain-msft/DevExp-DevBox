targetScope = 'subscription'

@description('Location for the deployment')
param location string

@description('Landing Zone Information')
var landingZone = loadJsonContent('settings/resourceOrganization/settings.json')

@description('Formatted Date Time')
param formattedDateTime string = utcNow()

@description('Monitoring Resources')
module monitoring '../src/management/monitoringModule.bicep' = {
  scope: subscription()
  name: 'monitoring-${formattedDateTime}'
  params: {
    landingZone: landingZone.management
    location: location
  }
}

output monitoringLogAnalyticsId string = monitoring.outputs.logAnalyticsId
output monitoringLogAnalyticsName string = monitoring.outputs.logAnalyticsName

@description('Deploy Connectivity Module')
module connectivity '../src/connectivity/connectivityModule.bicep' = {
  name: 'connectivity-${formattedDateTime}'
  params: {
    workspaceId: monitoring.outputs.logAnalyticsId
    location: location
    landingZone: landingZone.connectivity
  }
}

output connectivityVNetId string = connectivity.outputs.virtualNetworkId
output connectivityVNetName string = connectivity.outputs.virtualNetworkName
output virtualNetworkSubnets array = connectivity.outputs.virtualNetworkSubnets

@description('Compute Gallery')
module compute '../src/compute/computeGalleryModule.bicep' = {
  name: 'compute-${formattedDateTime}'
  params: {
    location: location
    landingZone: landingZone.computeGallery
  }
}

output computeGalleryName string = compute.outputs.computeGalleryName
output computeGalleryId string = compute.outputs.computeGalleryId

@description('Deploy Workload Module')
module workload '../src/workload/devCenterModule.bicep' = {
  name: 'workload-${formattedDateTime}'
  params: {
    sbunets: connectivity.outputs.virtualNetworkSubnets
    workspaceId: monitoring.outputs.logAnalyticsId
    landingZone: landingZone.workload
    location: location
    computeGalleryName: compute.outputs.computeGalleryName
    computeGalleryId: compute.outputs.computeGalleryId
  }
}

output workloadResourceGroup string = workload.outputs.workloadResourceGroupName
output workloadDevCenterId string = workload.outputs.devCenterId
output workloadDevCenterName string = workload.outputs.devCenterName
output workloadRoleAssignments array = workload.outputs.roleAssignments
output workloadNetConnections array = workload.outputs.netConnections
output workloadDevBoxDefinitions array = workload.outputs.devBoxDefinitions
output workloadDevCenterVnetAttachments array = workload.outputs.devCenterVnetAttachments
output workloadDevCenterCatalogs array = workload.outputs.devCenterCatalogs
output workloadDevCenterEnvironments array = workload.outputs.devCenterEnvironments
output workloadDevCenterProjects array = workload.outputs.devCenterprojects

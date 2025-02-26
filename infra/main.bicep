targetScope = 'subscription'

@description('Environment Name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string 

@description('Location for the deployment')
param location string = 'eastus2'

@description('Landing Zone Information')
var landingZone = loadJsonContent('settings/resourceOrganization/settings.json')

@description('Formatted Date Time')
param formattedDateTime string = utcNow()

@description('Monitoring Resources')
module monitoring '../src/management/monitoringModule.bicep' = {
  scope: subscription()
  name: 'monitoring-${formattedDateTime}'
  params: {
    environmentName: environmentName
    landingZone: landingZone.management
    location: location
  }
}

output monitoringResourceGroup string = monitoring.outputs.managementResourceGroupName
output monitoringLogAnalyticsName string = monitoring.outputs.logAnalyticsName

@description('Deploy Connectivity Module')
module connectivity '../src/connectivity/connectivityModule.bicep' = {
  name: 'connectivity-${formattedDateTime}'
  params: {
    environmentName: environmentName
    workspaceId: monitoring.outputs.logAnalyticsId
    location: location
    landingZone: landingZone.connectivity
  }
}

output connectivityResourceGroup string = connectivity.outputs.connectivityResourceGroupName
output connectivityVNetName string = connectivity.outputs.virtualNetworkName

@description('Compute Gallery')
module compute '../src/compute/computeGalleryModule.bicep' = {
  name: 'compute-${formattedDateTime}'
  params: {
    environmentName: environmentName
    location: location
    landingZone: landingZone.computeGallery
  }
}

output computeResourceGroup string = compute.outputs.computeResourceGroupName
output computeGalleryName string = compute.outputs.computeGalleryName

@description('Deploy Workload Module')
module workload '../src/workload/devCenterModule.bicep' = {
  name: 'workload-${formattedDateTime}'
  params: {
    environmentName: environmentName
    sbunets: connectivity.outputs.virtualNetworkSubnets
    workspaceId: monitoring.outputs.logAnalyticsId
    landingZone: landingZone.workload
    location: location
    computeGalleryName: compute.outputs.computeGalleryName
    computeGalleryId: compute.outputs.computeGalleryId
  }
}

output workloadResourceGroup string = workload.outputs.workloadResourceGroupName
output workloadDevCenterName string = workload.outputs.devCenterName
output workloadDevCenterProjects array = workload.outputs.devCenterprojects

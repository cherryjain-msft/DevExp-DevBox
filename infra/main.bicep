targetScope = 'subscription'

@description('Location for the deployment')
param location string

@description('Landing Zone Information')
var landingZone = loadJsonContent('settings/resourceOrganization/settings.json')

@description('Monitoring Resources')
module monitoring '../src/management/monitoringModule.bicep' = {
  scope: subscription()
  name: 'monitoring'
  params: {
    landingZone: landingZone.management
    location: location
  }
}

@description('Monitoring Log Analytics Id')
output monitoringLogAnalyticsId string = monitoring.outputs.logAnalyticsId
@description('Monitoring Log Analytics Name')
output monitoringLogAnalyticsName string = monitoring.outputs.logAnalyticsName

@description('Deploy Connectivity Module')
module connectivity '../src/connectivity/connectivityModule.bicep' = {
  name: 'connectivity'
  params: {
    workspaceId: monitoring.outputs.logAnalyticsId
    location: location
    landingZone: landingZone.connectivity
  }
}

@description('Connectivity vNet Id')
output connectivityVNetId string = connectivity.outputs.virtualNetworkId

@description('Connectivity vNet Name')
output connectivityVNetName string = connectivity.outputs.virtualNetworkName

@description('Compute Gallery')
module computeGallery '../src/computegallery/computeGalleryModule.bicep'= {
  name: 'computeGallery'
  params: {
    location: location
    landingZone: landingZone.computeGallery
  }
}

@description('Deploy Workload Module')
module workload '../src/workload/devCenterModule.bicep' = {
  name: 'workload'
  params: {
    networkConnections: connectivity.outputs.networkConnections
    workspaceId: monitoring.outputs.logAnalyticsId
    landingZone: landingZone.workload
    location: location
    computeGalleryName: computeGallery.outputs.computeGalleryName
    computeGalleryId: computeGallery.outputs.computeGalleryId
  }
}

@description('Workload Resource Group')
output workloadResourceGroup string = workload.outputs.workloadResourceGroupName

@description('Workload Dev Center Id')
output workloadDevCenterId string = workload.outputs.devCenterId

@description('Workload Dev Center Name')
output workloadDevCenterName string = workload.outputs.devCenterName

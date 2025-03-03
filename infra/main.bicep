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

@description('Connectivity Resource Group')
resource monitoringRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.management.create) {
  name: '${landingZone.management.name}-${environmentName}-rg'
  location: location
  tags: landingZone.management.tags
}

@description('Monitoring Resources')
module monitoring '../src/management/logAnalytics.bicep' = {
  scope: (landingZone.management.create ? monitoringRg : resourceGroup(landingZone.management.name))
  name: 'monitoring-${environmentName}'
  params: {
    name: landingZone.management.logAnalyticsName
  }
}

@description('Resource Group')
resource connectivityRg 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.connectivity.create) {
  name: '${landingZone.connectivity.name}-${environmentName}-rg'
  location: location
  tags: landingZone.connectivity.tags
}

@description('Deploy Connectivity Module')
module connectivity '../src/connectivity/connectivityModule.bicep' = {
  name: 'connectivity-${environmentName}'
  scope: (landingZone.connectivity.create ? connectivityRg : resourceGroup(landingZone.connectivity.name))
  params: {
    workspaceId: monitoring.outputs.logAnalyticsId
  }
}

output connectivityVNetName string = connectivity.outputs.virtualNetworkName

@description('Resource Group')
resource computeRg 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.computeGallery.create) {
  name: '${landingZone.computeGallery.name}-${environmentName}-rg'
  location: location
  tags: landingZone.computeGallery.tags
}

@description('Compute Gallery')
module compute '../src/compute/computeGalleryModule.bicep' = {
  name: 'compute-${environmentName}-${formattedDateTime}'
  scope: (landingZone.computeGallery.create ? computeRg : resourceGroup(landingZone.computeGallery.name))
}

output computeGalleryName string = compute.outputs.computeGalleryName


@description('Workload Resource Group')
resource workloadRg 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.workload.create) {
  name: '${landingZone.workload.name}-${environmentName}-rg'
  location: location
  tags: landingZone.workload.tags
}

@description('Deploy Workload Module')
module workload '../src/workload/devCenterModule.bicep' = {
  name: 'workload-${environmentName}'
  scope: (landingZone.workload.create ? workloadRg : resourceGroup(landingZone.workload.name))
  params: {
    sbunets: connectivity.outputs.virtualNetworkSubnets
    workspaceId: monitoring.outputs.logAnalyticsId
    computeGalleryName: compute.outputs.computeGalleryName
    computeGalleryId: compute.outputs.computeGalleryId
  }
}

output workloadDevCenterName string = workload.outputs.devCenterName
output workloadDevCenterProjects array = workload.outputs.devCenterprojects

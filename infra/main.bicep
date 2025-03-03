targetScope = 'subscription'

@description('Location for the deployment')
param location string = 'eastus2'

@description('Landing Zone Information')
var landingZones = loadYamlContent('settings/resourceOrganization/azureResources.yaml')

module landingZone '../src/resourcesOrganization/resourceGroup.bicep' = {
  name: 'landingZones'
  params: {
    landingZone: landingZones
  }
}

resource managemetRg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: landingZones.management.name
  location: location
}

module monitoring '../src/management/logAnalytics.bicep' = {
  scope: managemetRg
  name: landingZones.management.logAnalyticsName
  params: {
    name: landingZones.management.logAnalyticsName
  }
}

resource connectiviryRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: landingZones.connectivity.name
  location: location
}

@description('Deploy Connectivity Module')
module connectivity '../src/connectivity/connectivityModule.bicep' = {
  name: 'connectivity'
  scope: connectiviryRg
  params: {
    workspaceId: monitoring.outputs.logAnalyticsId
  }
}

resource computeRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: landingZones.compute.name
  location: location
}

@description('Compute Gallery')
module compute '../src/compute/computeGalleryModule.bicep' = {
  name: 'compute'
  scope: computeRg
}

resource workloadRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: landingZones.workload.name
  location: location
}

@description('Deploy Workload Module')
module workload '../src/workload/devCenterModule.bicep' = {
  name: 'workload'
  scope: workloadRg
  params: {
    sbunets: connectivity.outputs.virtualNetworkSubnets
    workspaceId: monitoring.outputs.logAnalyticsId
    computeGalleryName: compute.outputs.computeGalleryName
    computeGalleryId: compute.outputs.computeGalleryId
  }
}

// output workloadDevCenterName string = workload.outputs.devCenterName
// output workloadDevCenterProjects array = workload.outputs.devCenterprojects

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

@description('Deploy Connectivity Module')
module connectivity '../src/connectivity/connectivity.bicep' = {
  name: 'connectivity'
  params: {
    location: location
    landingZone: landingZones.connectivity
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

module workload '../src/workload/workload.bicep' = {
  name: 'workload'
  scope: subscription()
  params: {
    location: location
    landingZone: landingZones.workload
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsName
    computeGalleryName: compute.outputs.computeGalleryName
    computeGalleryResourceGroupName: computeRg.name
    subnets: connectivity.outputs.virtualNetworkSubnets
  }
}

targetScope = 'subscription'

@description('Solution Name')
param workloadName string

@description('Location for the deployment')
param location string

@description('Deployment Environment')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('Landing Zone Information')
var landingZone = environment == 'dev'
  ? loadJsonContent('settings/resourceOrganization/settings-dev.json')
  : loadJsonContent('settings/resourceOrganization/settings-prod.json')

@description('Connectivity Resource Group')
resource managementResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.management.create) {
  name: landingZone.management.name
  location: location
  tags: landingZone.management.tags
}

var managementResourceGroupName = (landingZone.management.create)
  ? managementResourceGroup.name
  : landingZone.management.name

@description('Monitoring Resources')
module monitoring '../src/management/monitoringModule.bicep' = {
  scope: subscription()
  name: 'monitoring'
  params: {
    name: landingZone.management.logAnalyticsName
  }
}

@description('Monitoring Log Analytics Id')
output monitoringLogAnalyticsId string = monitoring.outputs.logAnalyticsId
@description('Monitoring Log Analytics Name')
output monitoringLogAnalyticsName string = monitoring.outputs.logAnalyticsName

@description('Connectivity Resource Group')
resource connectivityResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.connectivity.create) {
  name: landingZone.connectivity.name
  location: location
  tags: landingZone.connectivity.tags
}

var connectivityResourceGroupName = (landingZone.connectivity.create)
  ? connectivityResourceGroup.name
  : landingZone.connectivity.name

@description('Deploy Connectivity Module')
module connectivity '../src/connectivity/connectivityModule.bicep' = {
  scope: resourceGroup(connectivityResourceGroupName)
  name: 'connectivity'
  params: {
    environment: environment
    workspaceId: monitoring.outputs.logAnalyticsId
  }
}

@description('Connectivity vNet Id')
output connectivityVNetId string = connectivity.outputs.virtualNetworkId

@description('Connectivity vNet Name')
output connectivityVNetName string = connectivity.outputs.virtualNetworkName

@description('Connectivity Resource Group')
resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.workload.create) {
  name: landingZone.workload.name
  location: location
  tags: landingZone.workload.tags
}

var workloadResourceGroupName = (landingZone.workload.create) ? workloadResourceGroup.name : landingZone.workload.name

@description('Deploy Workload Module')
module workload '../src/workload/devCenterModule.bicep' = {
  scope: resourceGroup(workloadResourceGroupName)
  name: 'workload'
  params: {
    networkConnections: connectivity.outputs.networkConnections
    environment: environment
    workspaceId: monitoring.outputs.logAnalyticsId
  }
}

@description('Workload Dev Center Id')
output workloadDevCenterId string = workload.outputs.devCenterId

@description('Workload Dev Center Name')
output workloadDevCenterName string = workload.outputs.devCenterName

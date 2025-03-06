targetScope = 'subscription'

@description('Location for the deployment')
param location string = 'eastus2'

@description('Key Vault Secret')
@secure()
param secretValue string

@description('Landing Zone Information')
var landingZones = loadYamlContent('settings/resourceOrganization/azureResources.yaml')

@description('Security Resource Group')
resource securityRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.security.create) {
  name: landingZones.security.name
  location: location
  tags: landingZones.security.tags
}

@description('Deploy Security Module')
module securityResources '../src/security/security.bicep' = {
  name: 'security'
  scope: resourceGroup(landingZones.security.name)
  params: {
    name: 'devexp'
    secretValue: secretValue
    tags: landingZones.security.tags
  }
}

@description('Monitoring Resource Group')
resource monitoringRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.monitoring.create) {
  name: landingZones.monitoring.name
  location: location
  tags: landingZones.monitoring.tags
}

resource existingMonitoringRg 'Microsoft.Resources/resourceGroups@2024-11-01' existing = {
  name: landingZones.monitoring.name
}

@description('Deploy Monitoring Module')
module monitoringResources '../src/management/logAnalytics.bicep' = {
  name: 'monitoring'
  scope: existingMonitoringRg
  params: {
    name: 'logAnalytics'
  }
}

@description('Connectivity Resource Group')
resource connectivityRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.connectivity.create) {
  name: landingZones.connectivity.name
  location: location
  tags: landingZones.connectivity.tags
}

resource existingconnectivityRg 'Microsoft.Resources/resourceGroups@2024-11-01' existing = {
  name: landingZones.connectivity.name
}

@description('Deploy Connectivity Module')
module connectivityResources '../src/connectivity/connectivity.bicep' = {
  name: 'connectivity'
  scope: existingconnectivityRg
  params: {
    workspaceId: monitoringResources.outputs.logAnalyticsId
  }
}

@description('Workload Resource Group')
resource workloadRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.workload.create) {
  name: landingZones.workload.name
  location: location
  tags: landingZones.workload.tags
}

@description('Deploy Workload Module')
module workloadResources '../src/workload/workload.bicep' = {
  name: 'workload'
  scope: resourceGroup(landingZones.workload.name)
  params: {
    logAnalyticsId: monitoringResources.outputs.logAnalyticsId
    subnets: connectivityResources.outputs.virtualNetworkSubnets
    secretIdentifier: securityResources.outputs.secretIdentifier
    keyVaultName: securityResources.outputs.keyVaultName
    securityResourceGroupName: landingZones.security.name
  }
}

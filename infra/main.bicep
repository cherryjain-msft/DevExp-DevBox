targetScope = 'subscription'

@description('Location for the deployment')
param location string = 'eastus2'

@description('Key Vault Secret')
@secure()
param secretValue string

@description('Landing Zone Information')
var landingZones = loadYamlContent('settings/resourceOrganization/azureResources.yaml')

@description('Workload Resource Group')
resource securityRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.security.create) {
  name: landingZones.security.name
  location: location
  tags: landingZones.security.tags
}

@description('Deploy Security Module')
module security '../src/security/security.bicep' = {
  scope: securityRg
  name: 'security'
  params: {
    name: 'devexp-kv'
    secretValue: secretValue
    tags: landingZones.security.tags
  }
}

@description('Workload Resource Group')
resource monitoringRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.monitoring.create) {
  name: landingZones.monitoring.name
  location: location
  tags: landingZones.monitoring.tags
}

@description('Deploy Monitoring Module')
module monitoring '../src/management/logAnalytics.bicep' = {
  scope: monitoringRg
  name: 'monitoring'
  params: {
    name: 'logAnalytics'
  }
}

@description('Workload Resource Group')
resource connectivityRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.connectivity.create) {
  name: landingZones.connectivity.name
  location: location
  tags: landingZones.connectivity.tags
}

@description('Deploy Connectivity Module')
module connectivity '../src/connectivity/connectivity.bicep' = {
  name: 'connectivity'
  scope: connectivityRg
  params: {
    workspaceId: monitoring.outputs.logAnalyticsId
  }
}

@description('Workload Resource Group')
resource workloadRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.workload.create) {
  name: landingZones.workload.name
  location: location
  tags: landingZones.workload.tags
}

@description('Deploy Workload Module')
module workload '../src/workload/workload.bicep' = {
  name: 'workload'
  scope: workloadRg
  params: {
    logAnalyticsId: monitoring.outputs.logAnalyticsId
    subnets: connectivity.outputs.virtualNetworkSubnets
    secretIdentifier: security.outputs.secretIdentifier
    keyVaultName: security.outputs.keyVaultName
    securityResourceGroupName: securityRg.name
  }
}

targetScope = 'subscription'

@description('Location for the deployment')
param location string = 'eastus2'

@description('Key Vault Secret')
@secure()
param secretValue string

param environmentName string

@description('Landing Zone Information')
var landingZones = loadYamlContent('settings/resourceOrganization/azureResources.yaml')

@description('Security Resource Group')
resource securityRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.security.create) {
  name: landingZones.security.name
  location: location
  tags: landingZones.security.tags
}

@description('Deploy Security Module')
module security '../src/security/security.bicep' = {
  name: 'security'
  scope: resourceGroup(landingZones.security.name)
  params: {
    keyVaultName: 'devexp'
    secretValue: secretValue
    secretName: 'gha-token'
    logAnalyticsId: monitoring.outputs.logAnalyticsId
    tags: landingZones.security.tags
  }
  dependsOn: [
    securityRg
  ]
}

var monitoringRgName = (landingZones.monitoring.create)
  ? '${landingZones.monitoring.name}-${environmentName}-rg'
  : landingZones.monitoring.name

@description('Monitoring Resource Group')
resource monitoringRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.monitoring.create) {
  name: monitoringRgName
  location: location
  tags: landingZones.monitoring.tags
}

@description('Deploy Monitoring Module')
module monitoring '../src/management/logAnalytics.bicep' = {
  name: 'monitoring'
  scope: resourceGroup(monitoringRgName)
  params: {
    name: 'logAnalytics'
  }
  dependsOn: [
    monitoringRg
  ]
}

var connectivityRgName = (landingZones.connectivity.create)
  ? '${landingZones.connectivity.name}-${environmentName}-rg'
  : landingZones.connectivity.name

@description('Connectivity Resource Group')
resource connectivityRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.connectivity.create) {
  name: connectivityRgName
  location: location
  tags: landingZones.connectivity.tags
}

@description('Deploy Connectivity Module')
module connectivity '../src/connectivity/connectivity.bicep' = {
  name: 'connectivity'
  scope: resourceGroup(connectivityRgName)
  params: {
    logAnalyticsId: monitoring.outputs.logAnalyticsId
  }
  dependsOn: [
    connectivityRg
  ]
}

var workloadRgName = (landingZones.workload.create)
  ? '${landingZones.workload.name}-${environmentName}-rg'
  : landingZones.workload.name

@description('Workload Resource Group')
resource workloadRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.workload.create) {
  name: workloadRgName
  location: location
  tags: landingZones.workload.tags
}

@description('Deploy Workload Module')
module workload '../src/workload/workload.bicep' = {
  name: 'workload'
  scope: resourceGroup(workloadRgName)
  params: {
    logAnalyticsId: monitoring.outputs.logAnalyticsId
    subnets: connectivity.outputs.virtualNetworkSubnets
    secretIdentifier: security.outputs.secretIdentifier
    keyVaultName: security.outputs.keyVaultName
    securityResourceGroupName: landingZones.security.name
  }
  dependsOn: [
    workloadRg
  ]
}

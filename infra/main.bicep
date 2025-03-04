targetScope = 'subscription'

@description('Location for the deployment')
param location string = 'eastus2'

@description('Key Vault Secret')
@secure()
param secretValue string

@description('Landing Zone Information')
var landingZone = loadYamlContent('settings/resourceOrganization/azureResources.yaml')

@description('Workload Resource Group')
resource securityRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.workload.create) {
  name: landingZone.security.name
  location: location
  tags: landingZone.security.tags
}

@description('Deploy Security Module')
module security '../src/security/security.bicep' = {
  scope: securityRg
  name: 'security'
  params: {
    name: 'devexp-kv'
    secretValue: secretValue
    tags: landingZone.security.tags
  }
}

@description('Workload Resource Group')
resource workloadRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.workload.create) {
  name: landingZone.workload.name
  location: location
  tags: landingZone.workload.tags
}

@description('Deploy Monitoring Module')
module monitoring '../src/management/logAnalytics.bicep' = {
  scope: workloadRg
  name: 'monitoring'
  params: {
    name: 'logAnalytics'
  }
}

@description('Deploy Connectivity Module')
module connectivity '../src/connectivity/connectivity.bicep' = {
  name: 'connectivity'
  scope: workloadRg
  params: {
    workspaceId: monitoring.outputs.logAnalyticsId
  }
}

@description('Deploy Workload Module')
module workload '../src/workload/workload.bicep' = {
  name: 'workload'
  scope: workloadRg
  params: {
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsName
    subnets: connectivity.outputs.virtualNetworkSubnets
    keyVaultName: security.outputs.keyVaultName
  }
}

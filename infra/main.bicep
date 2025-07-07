targetScope = 'subscription'

// Parameters with improved validation and documentation
@description('Azure region where resources will be deployed')
@allowed([
  'eastus'
  'eastus2'
  'westus'
  'westus2'
  'westus3'
  'centralus'
  'northeurope'
  'westeurope'
  'southeastasia'
  'australiaeast'
  'japaneast'
  'uksouth'
  'canadacentral'
  'swedencentral'
  'switzerlandnorth'
  'germanywestcentral'
])
param location string

@description('Secret value for Key Vault - GitHub Access Token')
@secure()
param secretValue string

@description('Environment name used for resource naming (dev, test, prod)')
@minLength(2)
@maxLength(10)
param environmentName string

// Load configuration from YAML
@description('Landing Zone resource organization')
var landingZones = loadYamlContent('settings/resourceOrganization/azureResources.yaml')

// Variables with consistent naming convention
var resourceNameSuffix = '${environmentName}-${location}-RG'

// Creates consistent resource group names
var createResourceGroupName = {
  security: landingZones.security.create
    ? '${landingZones.security.name}-${resourceNameSuffix}'
    : landingZones.security.name
  monitoring: landingZones.monitoring.create
    ? '${landingZones.monitoring.name}-${resourceNameSuffix}'
    : landingZones.monitoring.name
  workload: landingZones.workload.create
    ? '${landingZones.workload.name}-${resourceNameSuffix}'
    : landingZones.workload.name
}

var securityRgName = createResourceGroupName.security
var monitoringRgName = createResourceGroupName.monitoring
var workloadRgName = createResourceGroupName.workload

// Security resources
@description('Security Resource Group for Key Vault and related resources')
resource securityRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.security.create) {
  name: securityRgName
  location: location
  tags: union(landingZones.security.tags, {
    'component': 'security'
  })
}

// Monitoring resources
@description('Monitoring Resource Group for Log Analytics and related resources')
resource monitoringRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.monitoring.create) {
  name: monitoringRgName
  location: location
  tags: union(landingZones.monitoring.tags, {
    'component': 'monitoring'
  })
}

// Workload resources
@description('Workload Resource Group for DevCenter resources')
resource workloadRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZones.workload.create) {
  name: workloadRgName
  location: location
  tags: union(landingZones.workload.tags, {
    'component': 'workload'
  })
}

// Module deployments with improved names and organization
@description('Log Analytics Workspace for centralized monitoring')
module monitoring '../src/management/logAnalytics.bicep' = {
  name: 'monitoring-logAnalytics-deployment-${environmentName}'
  scope: resourceGroup(monitoringRgName)
  params: {
    name: 'logAnalytics'
  }
  dependsOn: [
    monitoringRg
  ]
}

@description('Security components including Key Vault')
module security '../src/security/security.bicep' = {
  name: 'security-keyvault-deployment-${environmentName}'
  scope: resourceGroup(securityRgName)
  params: {
    secretValue: secretValue
    logAnalyticsId: monitoring.outputs.logAnalyticsId
    tags: landingZones.security.tags
  }
  dependsOn: [
    securityRg
    monitoring
  ]
}

@description('DevCenter workload deployment')
module workload '../src/workload/workload.bicep' = {
  name: 'workload-devcenter-deployment-${environmentName}'
  scope: resourceGroup(workloadRgName)
  params: {
    environmentName: environmentName
    logAnalyticsId: monitoring.outputs.logAnalyticsId
    secretIdentifier: security.outputs.secretIdentifier
    keyVaultName: security.outputs.keyVaultName
    securityResourceGroupName: securityRgName
  }
  dependsOn: [
    workloadRg
    security
  ]
}

// Outputs with consistent naming and descriptions
@description('Name of the deployed Azure DevCenter')
output AZURE_DEV_CENTER_NAME string = workload.outputs.AZURE_DEV_CENTER_NAME

@description('List of project names deployed in the DevCenter')
output AZURE_DEV_CENTER_PROJECTS array = workload.outputs.AZURE_DEV_CENTER_PROJECTS

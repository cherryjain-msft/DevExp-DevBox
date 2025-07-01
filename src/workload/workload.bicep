/*
  Workload Module for DevCenter Resources
  -------------------------------------
  This module deploys the DevCenter workload and associated projects.
*/

// Parameters with improved validation and documentation
@description('Log Analytics Workspace Resource ID')
@minLength(1)
param logAnalyticsId string

@description('Network subnet configurations')
param virtualNetworks object[]

@description('Secret Identifier for secured content')
@secure()
param secretIdentifier string

@description('Key Vault Name for accessing secrets')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Security Resource Group Name')
@minLength(3)
param securityResourceGroupName string

// Resource types with documentation
@description('Landing Zone configuration type')
type LandingZone = {
  name: string
  create: bool
  tags: object
}

// Variables with clear naming
@description('Settings loaded from configuration file')
var devCenterSettings = loadYamlContent('../../infra/settings/workload/devcenter.yaml')

// Deploy core DevCenter infrastructure
@description('DevCenter Core Infrastructure')
module devcenter 'core/devCenter.bicep' = {
  name: 'devCenterDeployment'
  scope: resourceGroup()
  params: {
    config: devCenterSettings
    catalogs: devCenterSettings.catalogs
    environmentTypes: devCenterSettings.environmentTypes
    logAnalyticsId: logAnalyticsId
    virtualNetworks: virtualNetworks
    secretIdentifier: secretIdentifier
    keyVaultName: keyVaultName
    securityResourceGroupName: securityResourceGroupName
  }
}

// // Deploy individual projects with proper dependencies
// @description('DevCenter Projects')
// module projects 'project/project.bicep' = [
//   for (project, i) in devCenterSettings.projects: {
//     name: 'project-${project.name}'
//     scope: resourceGroup()
//     params: {
//       name: project.name
//       projectDescription: project.description ?? project.name
//       devCenterName: devcenter.outputs.AZURE_DEV_CENTER_NAME
//       projectCatalogs: project.catalogs
//       projectEnvironmentTypes: project.environmentTypes
//       projectPools: project.pools
//       networkConnectionName: devcenter.outputs.networkConnections[i].name
//       networkType: devcenter.outputs.networkConnections[i].virtualNetworkType
//       secretIdentifier: secretIdentifier
//       keyVaultName: keyVaultName
//       securityResourceGroupName: securityResourceGroupName
//       identity: project.identity
//       tags: project.tags
//     }
//     dependsOn: [
//       devcenter
//     ]
//   }
// ]

// // Outputs with clear naming and descriptions
// @description('Name of the deployed DevCenter')
// output AZURE_DEV_CENTER_NAME string = devcenter.outputs.AZURE_DEV_CENTER_NAME

// @description('List of project names deployed in the DevCenter')
// output AZURE_DEV_CENTER_PROJECTS array = [
//   for (project, i) in devCenterSettings.projects: projects[i].outputs.AZURE_PROJECT_NAME
// ]

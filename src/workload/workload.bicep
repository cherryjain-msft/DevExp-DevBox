@description('Log Analytics Workspace')
param logAnalyticsId string

@description('Subnets')
param subnets object[]

@description('Secret Identifier')
@secure()
param secretIdentifier string

@description('Key Vault Name')
param keyVaultName string

@description('Security Resource Group Name')
param securityResourceGroupName string

type LandingZone = {
  name: string
  create: bool
  tags: object
}

@description('Dev Center Settings')
var devCenterSettings = loadYamlContent('../../infra/settings/workload/devcenter.yaml')

@description('Deploy Dev Center Module')
module devcenter 'devCenter.bicep' = {
  name: 'devCenter'
  scope: resourceGroup()
  params: {
    config: devCenterSettings
    catalogs: devCenterSettings.catalogs
    environmentTypes: devCenterSettings.environmentTypes
    logAnalyticsId: logAnalyticsId
    subnets: subnets
    secretIdentifier: secretIdentifier
    keyVaultName: keyVaultName
    securityResourceGroupName: securityResourceGroupName
  }
}

@description('Dev Center Projects')
module projects 'project/project.bicep' = [
  for project in devCenterSettings.projects: {
    name: 'Project-${project.name}'
    scope: resourceGroup()
    params: {
      name: project.name
      projectDescription: project.name
      devCenterName: devcenter.outputs.devcCenterName
      projectCatalogs: project.catalogs
      projectEnvironmentTypes: project.environmentTypes
      projectPools: project.pools
      networkConnectionName: devcenter.outputs.networkConnectionName
      secretIdentifier: secretIdentifier
      keyVaultName: keyVaultName
      securityResourceGroupName: securityResourceGroupName
      identity: devCenterSettings.identity
      tags: project.tags
    }
    dependsOn: [
      devcenter
    ]
  }
]

output devCenterName string = devcenter.outputs.devcCenterName

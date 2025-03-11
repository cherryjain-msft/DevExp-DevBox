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
    projects: devCenterSettings.projects
    logAnalyticsId: logAnalyticsId
    subnets: subnets
    secretIdentifier: secretIdentifier
    keyVaultName: keyVaultName
    securityResourceGroupName: securityResourceGroupName
  }
}

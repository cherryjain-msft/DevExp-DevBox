@description('Log Analytics Workspace')
param logAnalyticsId string

@description('Subnets')
param subnets object[]

@description('Secret Identifier')
@secure()
param secretIdentifier string

@description('Key Vault Name')
param keyVaultName string

@description('Security Resouce Group Name')
param securityResourceGroupName string

type LandingZone = {
  name: string
  create: bool
  tags: object
}

@description('Dev Center Settings')
var devCenterConfig = loadYamlContent('../../infra/settings/workload/devcenter.yaml')

module workload 'devCenter.bicep' = {
  scope: resourceGroup()
  name: 'devCenter'
  params: {
    config: devCenterConfig
    devCenterCatalogs: devCenterConfig.catalogs
    devCenterEnvironmentTypes: devCenterConfig.environmentTypes
    devCenterProjects: devCenterConfig.projects
    logAnalyticsId: logAnalyticsId
    subnets: subnets
    secretIdentifier: secretIdentifier
    keyVaultName: keyVaultName
    securityResourceGroupName: securityResourceGroupName
  }
}

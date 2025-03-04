@description('Log Analytics Workspace')
param logAnalyticsId string

@description('Subnets')
param subnets NetWorkConection[]

@description('Secret Identifier')
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

type NetWorkConection = {
  name: string
  id: string
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
    devCenterDevBoxDefinitions: devCenterConfig.devBoxDefinitions
    secretIdentifier: secretIdentifier
    keyVaultName: keyVaultName
    securityResourceGroupName: securityResourceGroupName
  }
}

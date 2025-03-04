@description('Log Analytics Workspace')
param logAnalyticsWorkspaceName string

@description('Subnets')
param subnets NetWorkConection[]

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
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    subnets: subnets
    devCenterDevBoxDefinitions: devCenterConfig.devBoxDefinitions
  }
}

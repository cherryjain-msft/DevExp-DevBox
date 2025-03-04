targetScope = 'subscription'

@description('Location for the deployment')
param location string

@description('Landing Zone Information')
param landingZone LandingZone

@description('Log Analytics Workspace')
param logAnalyticsWorkspaceName string

@description('Compute Gallery Name')
param computeGalleryName string

@description('Compute Gallery Resource Group Name')
param computeGalleryResourceGroupName string

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

@description('Workload Resource Group')
resource workloadRg 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.create) {
  name: landingZone.name
  location: location
  tags: landingZone.tags
}

var rgName = landingZone.create ? workloadRg.name : landingZone.name

module workload 'devCenter.bicep' = {
  scope: resourceGroup(rgName)
  name: 'workload'
  params: {
    computeGalleryName: computeGalleryName
    computeGalleryResourceGroupName: computeGalleryResourceGroupName
    config: devCenterConfig
    devCenterCatalogs: devCenterConfig.catalogs
    devCenterEnvironmentTypes: devCenterConfig.environmentTypes
    devCenterProjects: devCenterConfig.projects
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    subnets: subnets
  }
}

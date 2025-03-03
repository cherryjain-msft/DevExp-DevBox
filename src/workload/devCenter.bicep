@description('Location')
param location string = resourceGroup().location

@description('Log Analytics Workspace')
param logAnalyticsWorkspaceName string

@description('Compute Gallery Name')
param computeGalleryName string


@description('Dev Center Settings')
var devCenterConfig = loadYamlContent('../../infra/settings/workload/devcenter.yaml')

resource devcenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' = {
  name: '${devCenterConfig.name}-${uniqueString(resourceGroup().id)}'
  location: location
  identity: {
    type: devCenterConfig.identity.type
  }
  properties: {
    projectCatalogSettings: {
      catalogItemSyncEnableStatus: devCenterConfig.catalogItemSyncEnableStatus
    }
    networkSettings: {
      microsoftHostedNetworkEnableStatus: devCenterConfig.microsoftHostedNetworkEnableStatus
    }
    devBoxProvisioningSettings: {
      installAzureMonitorAgentEnableStatus: devCenterConfig.installAzureMonitorAgentEnableStatus
    }
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
}

@description('Log Analytics Diagnostic Settings')
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: devcenter.name
  scope: devcenter
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalytics.id
  }
}

@description('Dev Center Catalogs')
module catalogs 'core/catalog.bicep' = [
  for catalog in devCenterConfig.catalogs: {
    name: catalog.name
    params: {
      devCenterName: devcenter.name
      catalogConfig: catalog
    }
  }
]

resource gallery 'Microsoft.Compute/galleries@2024-03-03' existing = {
  name: computeGalleryName
}

@description('Dev Center Compute Galleries')
module computeGallery 'core/computeGallery.bicep'= {
  name: 'computeGallery'
  params: {
    computeGalleryId: gallery.name
    computeGalleryName: gallery.id
    devCenterName: devcenter.name
  }
}

@description('Dev Center Environments')
module environments 'core/environmentType.bicep' = [
  for environment in devCenterConfig.environmentTypes: {
    name: environment.name
    params: {
      devCenterName: devcenter.name
      environmentConfig: environment
    }
  }
]

@description('Dev Center Projects')
module projects 'core/project.bicep' = [
  for project in devCenterConfig.projects: {
    name: project.name
    params: {
      devCenterName: devcenter.name
      projectConfig: project
    }
  }
]

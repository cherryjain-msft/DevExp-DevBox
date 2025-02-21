@description('The name of the Dev Center resource.')
param name string

@description('Deployment Environment')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('networkConnections')
param networkConnections array

@description('Log Analytics Workspace')
param workspaceId string

@description('Dev Center settings')
var settings = environment == 'dev'
  ? loadJsonContent('../../infra/settings/workload/settings.dev.json')
  : loadJsonContent('../../infra/settings/workload/settings.prod.json')

@description('Dev Center Resource')
resource devCenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' = {
  name: name
  location: resourceGroup().location
  tags: settings.tags
  identity: {
    type: settings.identity.type
    userAssignedIdentities: settings.identity.type == 'UserAssigned' ? settings.identity.userAssignedIdentities : null
  }
  properties: {
    projectCatalogSettings: {
      catalogItemSyncEnableStatus: settings.catalogItemSyncEnableStatus
    }
    networkSettings: {
      microsoftHostedNetworkEnableStatus: settings.microsoftHostedNetworkEnableStatus
    }
    devBoxProvisioningSettings: {
      installAzureMonitorAgentEnableStatus: settings.installAzureMonitorAgentEnableStatus
    }
  }
}

@description('Dev Center ID')
output devCenterId string = devCenter.id

@description('Dev Center Name')
output devCenterName string = devCenter.name

@description('Network Diagnostic Settings')
resource logAnalyticsDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'devCenter-DiagnosticSettings'
  scope: devCenter
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
    workspaceId: workspaceId
  }
}

module roleAssignments '../identity/devCenterRoleAssignments.bicep' = {
  name: 'roleAssignments'
  scope: subscription()
  params: {
    scope: 'subscription'
    principalId: devCenter.identity.principalId
    roles: settings.identity.roles
  }
}

@description('Dev Center Role Assignments')
output roleAssignments array = roleAssignments.outputs.roleAssignments

@description('Deploys Network Connections for the Dev Center')
module vNetAttachment 'devBoxConfiguration/networkConnections.bicep'= {
  name: 'vNetAttachments'
  scope: resourceGroup()
  params: {
    devCenterName: devCenter.name
    networkConnections: networkConnections
  }
}

@description('Network Connections')
output vNetAttachments array = vNetAttachment.outputs.vNetAttachments

@description('Compute Gallery')
resource computeGallery 'Microsoft.Compute/galleries@2024-03-03' = if (settings.computeGallery.create) {
  name:  '${settings.computeGallery.name}${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  tags: settings.computeGallery.tags
  properties: {
    description: 'Dev Center Compute Gallery'
  }
}

@description('Compute Gallery ID')
output computeGalleryId string = computeGallery.id

@description('Compute Gallery Name')
output computeGalleryName string = computeGallery.name

@description('DevCenter Compute Gallery')
resource devCenterGallery 'Microsoft.DevCenter/devcenters/galleries@2024-10-01-preview' = {
  name: computeGallery.name
  parent: devCenter
  properties: {
    galleryResourceId: computeGallery.id
  }
  dependsOn: [
    roleAssignments
  ]
}

@description('Dev Center DevBox Definitions')
module devBoxDefinitions 'devBoxConfiguration/devboxDefinitions.bicep' = {
  name: 'devBoxDefinitions'
  scope: resourceGroup()
  params: {
    devCenterName: devCenter.name
    definitions: settings.devBoxDefinitions
  }
}

@description('Dev Center DevBox Definitions')
output devBoxDefinitions array = devBoxDefinitions.outputs.devBoxDefinitions

@description('Dev Center Catalogs')
module devCenterCatalogs 'environmentConfiguration/catalogs.bicep'= {
  name: 'devCenterCatalogs'
  scope: resourceGroup()
  params: {
    devCenterCatalogs: settings.devCenterCatalogs
    devCenterName: devCenter.name
  }
}

@description('Dev Center Catalogs')
output devCenterCatalogs array = devCenterCatalogs.outputs.devCenterCatalogs

@description('Dev Center Environments')
module devCenterEnvironments 'environmentConfiguration/environmentTypes.bicep'= {
  name: 'devCenterEnvironmentTypes'
  scope: resourceGroup()
  params: {
    devCenterName: devCenter.name
    environmentTypes: settings.environmentTypes
  }
}

@description('Dev Center Environments')
output devCenterEnvironments array = devCenterEnvironments.outputs.devCenterEnvironments

@description('Dev Center Projects')
module projects 'projects/projectModule.bicep' = [
  for project in settings.projects: {
    name: '${project.name}-project'
    scope: resourceGroup()
    params: {
      name: project.name
      catalogs: project.catalogs
      devCenterId: devCenter.id
      roles: project.identity.roles
      environments: project.environments
      devBoxPools: project.pools
      tags: project.tags
    }
    dependsOn: [
     vNetAttachment
     devBoxDefinitions
    ]
  }
]

@description('Dev Center Projects')
output projects array = [
  for (project,i) in settings.projects: {
    id: projects[i].outputs.id
    name: project.name
  }
]

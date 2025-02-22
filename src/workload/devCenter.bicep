@description('networkConnections')
param networkConnections array

@description('Log Analytics Workspace')
param workspaceId string

@description('Dev Center settings')
param settings object

@description('Dev Center Resource')
resource devCenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' = {
  name: settings.devCenterName
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
resource vNetAttachment 'Microsoft.DevCenter/devcenters/attachednetworks@2024-10-01-preview' = [
  for connection in networkConnections: {
    name: connection.name
    parent: devCenter
    properties: {
      networkConnectionId: connection.id
    }
  }
]

@description('Network Connections')
output vNetAttachments array = [
  for (connection,i) in networkConnections: {
    id: vNetAttachment[i].id
    name: connection.name
  }
]

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
resource devBoxDefinitions 'Microsoft.DevCenter/devcenters/devboxdefinitions@2024-10-01-preview' = [
  for devBoxDefinition in settings.devBoxDefinitions: {
    name: devBoxDefinition.name
    tags: devBoxDefinition.tags
    location: resourceGroup().location
    parent: devCenter
    properties: {
      hibernateSupport: devBoxDefinition.hibernateSupport
      imageReference: {
        id: '${resourceId('Microsoft.DevCenter/devcenters/galleries/',devCenter.name,'Default')}/images/${devBoxDefinition.image}'
      }
      sku: {
        name: devBoxDefinition.sku
      }
    }
  }
]

@description('Dev Center DevBox Definitions')
output devBoxDefinitions array = [
  for (devBoxDefinition,i) in settings.devBoxDefinitions: {
    id: devBoxDefinitions[i].id
    name: devBoxDefinition.name
  }
]


@description('Dev Center Catalogs')
resource catalogs 'Microsoft.DevCenter/devcenters/catalogs@2024-10-01-preview' = [
  for catalog in settings.devCenterCatalogs: {
    name: catalog.name
    parent: devCenter
    properties: (catalog.gitHub)
      ? {
          gitHub: {
            uri: catalog.uri
            branch: catalog.branch
            path: catalog.path
          }
          syncType: 'Scheduled'
        }
      : {
          adoGit: {
            uri: catalog.uri
            branch: catalog.branch
            path: catalog.path
          }
          syncType: 'Scheduled'
        }
  }
]

@description('Dev Center Catalogs')
output devCenterCatalogs array = [
  for (catalog,i) in settings.devCenterCatalogs: {
    id: catalogs[i].id
    name: catalogs[i].name
  }
]

@description('Dev Center Environments')
resource devCenterEnvironments 'Microsoft.DevCenter/devcenters/environmentTypes@2024-10-01-preview' = [
  for environment in settings.environmentTypes: {
    name: environment.name
    parent: devCenter
    tags: environment.tags
    properties: {
      displayName: environment.name
    }
  }
]

@description('Dev Center Environments')
output devCenterEnvironments array = [
  for (environment,i) in settings.environmentTypes: {
    id: devCenterEnvironments[i].id
    name: environment.name
  }
]


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


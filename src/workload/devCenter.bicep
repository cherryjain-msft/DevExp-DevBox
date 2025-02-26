@description('subnets')
param subnets array

@description('Log Analytics Workspace')
param workspaceId string

@description('Dev Center settings')
param settings object

@description('Dev Center Compute Gallery')
param computeGalleryName string

@description('Compute Gallery ID')
param computeGalleryId string

param formattedDateTime string = utcNow()

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

output devCenterId string = devCenter.id
output devCenterName string = devCenter.name

@description('DevCenter Diagnostic Settings')
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: devCenter.name
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

output diagnosticSettingsId string = diagnosticSettings.id
output diagnosticSettingsName string = diagnosticSettings.name
output diagnosticSettingsType string = diagnosticSettings.type

module roleAssignments '../identity/devCenterRoleAssignments.bicep' = {
  name: 'roleAssignments-${formattedDateTime}'
  scope: subscription()
  params: {
    scope: 'subscription'
    principalId: devCenter.identity.principalId
    roles: settings.identity.roles
  }
}

output roleAssignments array = roleAssignments.outputs.roleAssignments

@description('Network Connections for the Virtual Network Subnets')
resource netConnection 'Microsoft.DevCenter/networkConnections@2024-10-01-preview' = [
  for (subnet, i) in subnets: {
    name: subnet.name
    location: resourceGroup().location
    tags: settings.tags
    properties: {
      domainJoinType: 'AzureADJoin'
      subnetId: subnet.id
    }
  }
]

output netConnection array = [
  for (connection, i) in subnets: {
    id: netConnection[i].id
    name: connection.name
  }
]

@description('Deploys Network Connections for the Dev Center')
resource vNetConnections 'Microsoft.DevCenter/devcenters/attachednetworks@2024-10-01-preview' = [
  for (connection, i) in subnets: {
    name: connection.name
    parent: devCenter
    properties: {
      networkConnectionId: netConnection[i].id
    }
  }
]

output devCenterVnetConnections array = [
  for (connection, i) in subnets: {
    id: vNetConnections[i].id
    name: connection.name
  }
]

@description('DevCenter Compute Gallery')
resource devCenterGallery 'Microsoft.DevCenter/devcenters/galleries@2024-10-01-preview' = {
  name: computeGalleryName
  parent: devCenter
  properties: {
    galleryResourceId: computeGalleryId
  }
  dependsOn: [
    roleAssignments
  ]
}

output devCenterGalleryId string = devCenterGallery.id
output devCenterGalleryName string = devCenterGallery.name

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

output devBoxDefinitions array = [
  for (devBoxDefinition, i) in settings.devBoxDefinitions: {
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

output devCenterCatalogs array = [
  for (catalog, i) in settings.devCenterCatalogs: {
    id: catalogs[i].id
    name: catalogs[i].name
  }
]

@description('Dev Center Environments')
resource environmentTypes 'Microsoft.DevCenter/devcenters/environmentTypes@2024-10-01-preview' = [
  for environment in settings.environmentTypes: {
    name: environment.name
    parent: devCenter
    tags: environment.tags
    properties: {
      displayName: environment.name
    }
  }
]

output devCenterEnvironments array = [
  for (environment, i) in settings.environmentTypes: {
    id: environmentTypes[i].id
    name: environment.name
  }
]

@description('Dev Center Projects')
module projects 'projects/projectModule.bicep' = [
  for project in settings.projects: {
    name: '${project.name}-project-${formattedDateTime}'
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
      vNetConnections
      devBoxDefinitions
    ]
  }
]

output projects array = [
  for (project, i) in settings.projects: {
    id: projects[i].outputs.id
    name: project.name
  }
]

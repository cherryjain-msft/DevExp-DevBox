@description('Configuration')
param config DevCenterconfig

@description('Dev Center Catalogs')
param devCenterCatalogs Catalog[]

@description('Environment Types')
param devCenterEnvironmentTypes EnvironmentType[]

@description('Projects')
param devCenterProjects Project[]

@description('Log Analytics Workspace')
param logAnalyticsWorkspaceName string

@description('Compute Gallery Name')
param computeGalleryName string

@description('Compute Gallery Resource Group Name')
param computeGalleryResourceGroupName string

@description('Subnets')
param subnets NetWorkConection[]

type DevCenterconfig = {
  name: string
  identity: Identity
  catalogItemSyncEnableStatus: string
  microsoftHostedNetworkEnableStatus: string
  installAzureMonitorAgentEnableStatus: string
}

type Identity = {
  type: string
  roleAssignments: string[]
}

type Catalog = {
  name: string
  type: string
  uri: string
  branch: string
  path: string
}

type EnvironmentType = {
  name: string
}

type ProjectEnvironmentType = {
  name: string
  deploymentTargetId: string
}

type Project = {
  name: string
  description: string
  environmentTypes: ProjectEnvironmentType[]
  catalogs: Catalog[]
}

type NetWorkConection = {
  name: string
  id: string
}

resource devcenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' = {
  name: '${config.name}-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  identity: {
    type: config.identity.type
  }
  properties: {
    projectCatalogSettings: {
      catalogItemSyncEnableStatus: config.catalogItemSyncEnableStatus
    }
    networkSettings: {
      microsoftHostedNetworkEnableStatus: config.microsoftHostedNetworkEnableStatus
    }
    devBoxProvisioningSettings: {
      installAzureMonitorAgentEnableStatus: config.installAzureMonitorAgentEnableStatus
    }
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: resourceGroup().location
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

@description('Dev Center Identity Role Assignments')
module roleAssignments '../identity/devCenterRoleAssignment.bicep' = [
  for role in config.identity.roleAssignments: {
    name: '${role}-roleAssignments'
    scope: subscription()
    params: {
      role: role
      principalId: devcenter.identity.principalId
    }
  }
]

@description('Network Connections')
module networkConnections 'core/networkConnection.bicep' = [
  for subnet in subnets: {
    name: '${config.name}-${subnet.name}'
    params: {
      name: subnet.name
      devcenterNae: devcenter.name
      subnetId: subnet.id
    }
  }
]

@description('Dev Center Catalogs')
module catalogs 'core/catalog.bicep' = [
  for catalog in devCenterCatalogs: {
    name: catalog.name
    params: {
      devCenterName: devcenter.name
      catalogConfig: catalog
    }
  }
]

resource gallery 'Microsoft.Compute/galleries@2024-03-03' existing = {
  name: computeGalleryName
  scope: resourceGroup(computeGalleryResourceGroupName)
}

@description('Dev Center Compute Galleries')
module computeGallery 'core/computeGallery.bicep' = {
  name: 'devCenter-computeGallery'
  params: {
    computeGalleryId: gallery.id
    computeGalleryName: gallery.name
    devCenterName: devcenter.name
  }
  dependsOn: [
    roleAssignments
  ]
}

@description('Dev Center Environments')
module environments 'core/environmentType.bicep' = [
  for environment in devCenterEnvironmentTypes: {
    name: environment.name
    params: {
      devCenterName: devcenter.name
      environmentConfig: environment
    }
  }
]

@description('Dev Center Projects')
module projects 'core/project.bicep' = [
  for project in devCenterProjects: {
    name: project.name
    params: {
      devCenterName: devcenter.name
      projectConfig: project
    }
  }
]

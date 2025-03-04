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

@description('DevBox definitions')
param devCenterDevBoxDefinitions DevBoxDefinition[]

@description('Subnets')
param subnets NetWorkConection[]

type DevCenterconfig = {
  name: string
  identity: Identity
  catalogItemSyncEnableStatus: Status
  microsoftHostedNetworkEnableStatus: Status
  installAzureMonitorAgentEnableStatus: Status
  tags: object
}

type Status = 'Enabled' | 'Disabled'

type Identity = {
  type: string
  roleAssignments: string[]
}

type Catalog = {
  name: string
  type: CatalogType
  uri: string
  branch: string
  path: string
}

type CatalogType = 'gitHub' | 'adoGit'

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
  pools: array
  tags: object
}

type NetWorkConection = {
  name: string
  id: string
}

type DevBoxDefinition = {
  name: string
  image: string
  osStorageType: StorageType
  imageVersion: string
  sku: string
  hibernateSupport: HibernateSupport
  default: bool
}

type HibernateSupport = 'Enabled' | 'Disabled'

type StorageType = 'ssd_128gb' | 'ssd_256gb' | 'ssd_512gb' | 'ssd_1tb'

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
  tags: config.tags
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-10-01' existing = {
  name: logAnalyticsWorkspaceName
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
      devCenterName: devcenter.name
      subnetId: subnet.id
    }
  }
]

output networkConnectionNames array = [
  for subnet in subnets: {
    name: networkConnections[0].outputs.vnetAttachmentName
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

@description('Dev Center DevBox Definitions')
module devBoxDefinitions 'core/devBoxDefinition.bicep' = [
  for devBoxDefinition in devCenterDevBoxDefinitions: {
    name: devBoxDefinition.name
    params: {
      name: devBoxDefinition.name
      location: resourceGroup().location
      devCenterName: devcenter.name
      hibernateSupport: devBoxDefinition.hibernateSupport
      imageName: devBoxDefinition.image
      osStorageType: devBoxDefinition.osStorageType
      sku: devBoxDefinition.sku
    }
  }
]

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
      name: project.name
      projectDescription: project.name
      devCenterName: devcenter.name
      projectCatalogs: project.catalogs
      projectEnvironmentTypes: project.environmentTypes
      projectPools: project.pools
      networkConnectionName: networkConnections[0].outputs.vnetAttachmentName
      tags: project.tags
    }
  }
]

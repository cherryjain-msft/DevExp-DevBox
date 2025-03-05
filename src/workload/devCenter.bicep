@description('Configuration')
param config DevCenterconfig

@description('Dev Center Catalogs')
param devCenterCatalogs Catalog[]

@description('Environment Types')
param devCenterEnvironmentTypes EnvironmentType[]

@description('Projects')
param devCenterProjects Project[]

@description('DevBox definitions')
param devCenterDevBoxDefinitions DevBoxDefinition[]

@description('Subnets')
param subnets NetWorkConection[]

@description('Log Analytics Workspace Id')
param logAnalyticsId string

@description('Secret Identifier')
param secretIdentifier string

@description('Key Vault Name')
param keyVaultName string

@description('Security Resouce Group Name')
param securityResourceGroupName string

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
  roleAssignments: RoleAssignment[]
}

type RoleAssignment = {
  name: string
  id: string
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
  name: config.name
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

@description('Key Vault Access Policies')
module keyVaultAccessPolicies '../security/keyvault-access.bicep' = {
  name: 'keyVaultAccessPolicies'
  scope: resourceGroup(securityResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    principalId: devcenter.identity.principalId
  }
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
    workspaceId: logAnalyticsId
  }
}

@description('Dev Center Identity Role Assignments')
module roleAssignments '../identity/devCenterRoleAssignment.bicep' = [
  for role in config.identity.roleAssignments: {
    name: 'roleAssignments-${replace(role.name, ' ', '-')}'
    scope: subscription()
    params: {
      id: role.id
      principalId: devcenter.identity.principalId
    }
  }
]

@description('Network Connections')
module networkConnections 'core/networkConnection.bicep' = [
  for subnet in subnets: {
    name: 'networkConnections-${subnet.name}'
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
    name: 'catalogs-${catalog.name}'
    params: {
      devCenterName: devcenter.name
      catalogConfig: catalog
      secretIdentifier: secretIdentifier
    }
  }
]

@description('Dev Center DevBox Definitions')
module devBoxDefinitions 'core/devBoxDefinition.bicep' = [
  for devBoxDefinition in devCenterDevBoxDefinitions: {
    name: 'devBoxDefinitions-${devBoxDefinition.name}'
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
    name: 'environmentTypes-${environment.name}'
    params: {
      devCenterName: devcenter.name
      environmentConfig: environment
    }
  }
]

@description('Dev Center Projects')
module projects 'core/project.bicep' = [
  for project in devCenterProjects: {
    name: 'Projects-${project.name}'
    params: {
      name: project.name
      projectDescription: project.name
      devCenterName: devcenter.name
      projectCatalogs: project.catalogs
      projectEnvironmentTypes: project.environmentTypes
      projectPools: project.pools
      networkConnectionName: networkConnections[0].outputs.vnetAttachmentName
      secretIdentifier: secretIdentifier
      keyVaultName: keyVaultName
      securityResourceGroupName: securityResourceGroupName
      tags: project.tags
    }
  }
]

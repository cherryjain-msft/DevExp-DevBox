@description('Configuration')
param config DevCenterConfig

@description('Dev Center Catalogs')
param catalogs object[]

@description('Environment Types')
param environmentTypes object[]

@description('Projects')
param projects object[]

@description('Subnets')
param subnets object[]

@description('Log Analytics Workspace Id')
param logAnalyticsId string

@description('Secret Identifier')
@secure()
param secretIdentifier string

@description('Key Vault Name')
param keyVaultName string

@description('Security Resource Group Name')
param securityResourceGroupName string

type DevCenterConfig = {
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

type CatalogType = 'gitHub' | 'adoGit'

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
module networkConnection 'core/networkConnection.bicep' = [
  for subnet in subnets: {
    name: 'networkConnections-${subnet.name}'
    params: {
      name: subnet.name
      devCenterName: devcenter.name
      subnetId: subnet.id
    }
  }
]

@description('Network Connections Output')
output networkConnections array = [
  for subnet in subnets: {
    name: networkConnection[0].outputs.vnetAttachmentName
  }
]

@description('Dev Center Catalogs')
module catalog 'core/catalog.bicep' = [
  for catalog in catalogs: {
    name: 'catalogs-${catalog.name}'
    params: {
      devCenterName: devcenter.name
      catalogConfig: catalog
      secretIdentifier: secretIdentifier
    }
  }
]

@description('Dev Center Environments')
module environment 'core/environmentType.bicep' = [
  for environment in environmentTypes: {
    name: 'environmentTypes-${environment.name}'
    params: {
      devCenterName: devcenter.name
      environmentConfig: environment
    }
  }
]

@description('Dev Center Projects')
module project 'project/project.bicep' = [
  for project in projects: {
    name: 'Projects-${project.name}'
    params: {
      name: project.name
      projectDescription: project.name
      devCenterName: devcenter.name
      projectCatalogs: project.catalogs
      projectEnvironmentTypes: project.environmentTypes
      projectPools: project.pools
      networkConnectionName: networkConnection[0].outputs.vnetAttachmentName
      secretIdentifier: secretIdentifier
      keyVaultName: keyVaultName
      securityResourceGroupName: securityResourceGroupName
      tags: project.tags
    }
  }
]

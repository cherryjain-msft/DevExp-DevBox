@description('Configuration')
param config DevCenterConfig

@description('Dev Center Catalogs')
param catalogs object[]

@description('Environment Types')
param environmentTypes object[]

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
  roleAssignments: RoleAssignment
}

type RoleAssignment = {
  devCenter: AzureRBACRole[]
  orgRoleType: OrgRoleType[]
}

type AzureRBACRole = {
  id: string
  name: string
}

type OrgRoleType = {
  type: string
  azureADGroupId: string
  azureADGroupName: string
  azureRBACRoles: AzureRBACRole[]
}

@description('Dev Center Resource')
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

output AZURE_DEV_CENTER_NAME string = devcenter.name

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
module devCenterIdentityRoleAssignment '../identity/devCenterRoleAssignment.bicep' = [
  for role in config.identity.roleAssignments.devCenter: {
    name: 'RBAC-${guid(role.id, role.name,resourceGroup().id)}'
    scope: subscription()
    params: {
      id: role.id
      principalId: devcenter.identity.principalId
    }
    dependsOn: [
      keyVaultAccessPolicies
    ]
  }
]

@description('Dev Center Identity User Groups role assignments')
module devCenterIdentityUserGroupsRoleAssignment '../identity/orgRoleAssignment.bicep' = [
  for role in config.identity.roleAssignments.orgRoleType: {
    name: 'RBAC-${guid(role.azureADGroupId, role.azureADGroupName,role.azureRBACRoles[0].id,resourceGroup().id)}'
    scope: resourceGroup()
    params: {
      devCenterName: devcenter.name
      principalId: role.azureADGroupId
      roles: role.azureRBACRoles
    }
    dependsOn: [
      devCenterIdentityRoleAssignment
    ]
  }
]

@description('Network Connections')
module networkConnection 'core/networkConnection.bicep' = [
  for subnet in subnets: {
    name: 'networkConnections-${subnet.name}'
    scope: resourceGroup()
    params: {
      name: 'nc-${subnet.name}'
      devCenterName: devcenter.name
      subnetId: subnet.id
    }
  }
]

@description('Network Connections Output')
output networkConnectionName string = networkConnection[0].outputs.vnetAttachmentName

@description('Dev Center Catalogs')
module catalog 'core/catalog.bicep' = [
  for catalog in catalogs: {
    name: 'catalog-${catalog.name}'
    scope: resourceGroup()
    params: {
      devCenterName: devcenter.name
      catalogConfig: catalog
      secretIdentifier: secretIdentifier
    }
    dependsOn: [
      keyVaultAccessPolicies
    ]
  }
]

@description('Dev Center Environments')
module environment 'core/environmentType.bicep' = [
  for environment in environmentTypes: {
    name: 'environmentType-${environment.name}'
    scope: resourceGroup()
    params: {
      devCenterName: devcenter.name
      environmentConfig: environment
    }
  }
]

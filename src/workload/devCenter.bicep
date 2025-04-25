// Common variables for reuse
var devCenterName = config.name
var devCenterPrincipalId = devcenter.identity.principalId

// Parameters with improved metadata and validation
@description('DevCenter configuration including identity and settings')
param config DevCenterConfig

@description('Dev Center Catalogs')
param catalogs array

@description('Environment Types')
param environmentTypes array

@description('Network type for resource deployment')
@allowed(['Unmanaged', 'Managed'])
param networkType string

@description('Subnets')
param subnets array

@description('Log Analytics Workspace Id')
@minLength(1)
param logAnalyticsId string

@description('Secret Identifier')
@secure()
param secretIdentifier string

@description('Key Vault Name')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Security Resource Group Name')
param securityResourceGroupName string

// Type definitions with proper naming conventions
@description('DevCenter configuration type')
type DevCenterConfig = {
  name: string
  identity: Identity
  catalogItemSyncEnableStatus: Status
  microsoftHostedNetworkEnableStatus: Status
  installAzureMonitorAgentEnableStatus: Status
  tags: object
}

@description('Status type for feature toggles')
type Status = 'Enabled' | 'Disabled'

@description('Identity configuration type')
type Identity = {
  type: string
  roleAssignments: RoleAssignment
}

@description('Role assignment configuration')
type RoleAssignment = {
  devCenter: AzureRBACRole[]
  orgRoleTypes: OrgRoleType[]
}

@description('Azure RBAC role definition')
type AzureRBACRole = {
  id: string
  name: string
}

@description('Organization role type configuration')
type OrgRoleType = {
  type: string
  azureADGroupId: string
  azureADGroupName: string
  azureRBACRoles: AzureRBACRole[]
}

// Main DevCenter resource
@description('Dev Center Resource')
resource devcenter 'Microsoft.DevCenter/devcenters@2025-02-01' = {
  name: devCenterName
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

// Security configuration
@description('Key Vault Access Policies')
module keyVaultAccessPolicies '../security/keyvault-access.bicep' = {
  name: 'keyVaultAccessPolicies-${devCenterName}'
  scope: resourceGroup(securityResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    principalId: devCenterPrincipalId
  }
}

// Monitoring configuration
@description('Log Analytics Diagnostic Settings')
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${devCenterName}-diagnostics'
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

// RBAC and Identity Management
@description('Dev Center Identity Role Assignments')
module devCenterIdentityRoleAssignment '../identity/devCenterRoleAssignment.bicep' = [
  for (role, i) in config.identity.roleAssignments.devCenter: {
    name: 'RBACDevCenter-${i}-${devCenterName}'
    scope: subscription()
    params: {
      id: role.id
      principalId: devCenterPrincipalId
    }
    dependsOn: [
      keyVaultAccessPolicies
    ]
  }
]

@description('Dev Center Identity User Groups role assignments')
module devCenterIdentityUserGroupsRoleAssignment '../identity/orgRoleAssignment.bicep' = [
  for (role, i) in config.identity.roleAssignments.orgRoleTypes: {
    name: 'RBACUserGroup-${i}-${devCenterName}'
    scope: subscription()
    params: {
      principalId: role.azureADGroupId
      roles: role.azureRBACRoles
    }
    dependsOn: [
      devCenterIdentityRoleAssignment
    ]
  }
]

// Network configuration
@description('Network Connections')
module networkConnection 'core/networkConnection.bicep' = [
  for (subnet, i) in subnets: if (networkType == 'Unmanaged') {
    name: 'networkConnection-${i}-${devCenterName}'
    scope: resourceGroup()
    params: {
      name: 'nc-${subnet.name}'
      devCenterName: devCenterName
      subnetId: subnet.id
    }
  }
]

// Catalog configuration
@description('Dev Center Catalogs')
module catalog 'core/catalog.bicep' = [
  for (catalog, i) in catalogs: {
    name: 'catalog-${i}-${devCenterName}'
    scope: resourceGroup()
    params: {
      devCenterName: devCenterName
      catalogConfig: catalog
      secretIdentifier: secretIdentifier
    }
    dependsOn: [
      keyVaultAccessPolicies
    ]
  }
]

// Environment types configuration
@description('Dev Center Environments')
module environment 'core/environmentType.bicep' = [
  for (environment, i) in environmentTypes: {
    name: 'environmentType-${i}-${devCenterName}'
    scope: resourceGroup()
    params: {
      devCenterName: devCenterName
      environmentConfig: environment
    }
  }
]

// Outputs with clear descriptions
@description('Deployed Dev Center name')
output AZURE_DEV_CENTER_NAME string = devCenterName

@description('Network Connection Name for Dev Center')
output networkConnectionName string = (networkType == 'Unmanaged') ? networkConnection[0].name : 'Managed'

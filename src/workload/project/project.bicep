@description('Name of the DevCenter instance')
param devCenterName string

@description('Name of the project to be created')
param name string

@description('Description for the DevCenter project')
param projectDescription string

@description('Catalog configuration for the project')
param projectCatalogs object

@description('Environment types to be associated with the project')
param projectEnvironmentTypes array

@description('DevBox pool configurations for the project')
param projectPools array

@description('Name of the network connection to be used with DevBox pools')
param networkConnectionName string

@description('Network type for resource deployment')
@allowed(['Unmanaged', 'Managed'])
param networkType string

@description('Secret identifier for Git repository authentication')
@secure()
param secretIdentifier string

@description('Name of the Key Vault containing secrets')
param keyVaultName string

@description('Resource group name for security resources')
param securityResourceGroupName string

@description('Managed identity configuration for the project')
param identity Identity

@description('Tags to be applied to all resources')
param tags object = {}

@description('Identity configuration for the project')
type Identity = {
  @description('Type of managed identity (SystemAssigned or UserAssigned)')
  type: string

  @description('Role assignments for Azure AD groups')
  roleAssignments: RoleAssignment[]
}

@description('Azure RBAC role definition')
type AzureRBACRole = {
  @description('Role definition ID')
  id: string

  @description('Display name of the role')
  name: string
}

@description('Role assignment configuration')
type RoleAssignment = {
  @description('Azure AD group object ID')
  azureADGroupId: string

  @description('Azure AD group display name')
  azureADGroupName: string

  @description('Azure RBAC roles to assign')
  azureRBACRoles: AzureRBACRole[]
}

@description('Reference to existing DevCenter')
resource devCenter 'Microsoft.DevCenter/devcenters@2025-02-01' existing = {
  name: devCenterName
}

@description('DevCenter Project resource')
resource project 'Microsoft.DevCenter/projects@2025-02-01' = {
  name: name
  location: resourceGroup().location
  identity: {
    type: identity.type
  }
  properties: {
    description: projectDescription
    devCenterId: devCenter.id
    displayName: name
    catalogSettings: {
      catalogItemSyncTypes: [
        'EnvironmentDefinition'
        'ImageDefinition'
      ]
    }
  }
  tags: union(tags, {
    'ms-resource-usage': 'azure-cloud-devbox'
    'project': name
  })
}

@description('Role assignment resource')
module roleAssignment '../../identity/keyVaultAccess.bicep' = {
  scope: resourceGroup(securityResourceGroupName)
  params: {
    name: project.name
    principalId: project.identity.principalId
  }
  dependsOn: [
    project
  ]
}

@description('Configure project identity role assignments')
module projectIdentity '../../identity/projectIdentityRoleAssignment.bicep' = [
  for (role, i) in identity.roleAssignments: {
    name: 'prj-rbac-${i}-${uniqueString(project.id, role.azureADGroupId)}'
    scope: subscription()
    params: {
      projectName: project.name
      principalId: role.azureADGroupId
      roles: role.azureRBACRoles
    }
  }
]

@description('Configure environment definition catalogs')
module catalogs 'projectCatalog.bicep' = {
  name: 'catalog-${uniqueString(project.id)}'
  scope: resourceGroup()
  params: {
    projectName: project.name
    catalogConfig: projectCatalogs
    secretIdentifier: secretIdentifier
  }
  dependsOn: [
    projectIdentity
  ]
}

@description('Configure project environment types')
module environmentTypes 'projectEnvironmentType.bicep' = [
  for (envType, i) in projectEnvironmentTypes: {
    name: 'env-type-${i}-${uniqueString(project.id, envType.name)}'
    scope: resourceGroup()
    params: {
      projectName: project.name
      environmentConfig: envType
    }
    dependsOn: [
      projectIdentity
    ]
  }
]

@description('Configure DevBox pools for the project')
module pools 'projectPool.bicep' = [
  for (pool, i) in projectPools: {
    name: 'pool-${i}-${uniqueString(project.id, pool.name)}'
    scope: resourceGroup()
    params: {
      name: pool.name
      projectName: project.name
      catalogName: projectCatalogs.imageDefinition.name
      imageDefinitionName: pool.imageDefinitionName
      networkConnectionName: networkConnectionName
      networkType: networkType
    }
    dependsOn: [
      projectIdentity
      catalogs
    ]
  }
]

@description('The name of the deployed project')
output AZURE_PROJECT_NAME string = project.name

@description('The resource ID of the deployed project')
output AZURE_PROJECT_ID string = project.id

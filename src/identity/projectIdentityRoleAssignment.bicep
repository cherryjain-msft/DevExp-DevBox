targetScope = 'subscription'
@description('The name of the DevCenter project')
param projectName string

@description('The principal (object) ID to assign roles to')
param principalId string

@description('Array of role definitions to assign to the principal')
param roles array

@description('The principal type for the role assignments')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
  'ForeignGroup'
  'Device'
])
param principalType string = 'Group'

// @description('Reference to the existing DevCenter project')
// resource project 'Microsoft.DevCenter/projects@2025-02-01' existing = {
//   scope: resou
//   name: projectName
// }

@description('Role assignments for the project')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in roles: {
    name: guid(deployer().objectId, principalId, role.id)
    scope: subscription()
    properties: {
      principalId: principalId
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', role.id)
      principalType: principalType
      description: contains(role, 'name')
        ? 'Role: ${role.name} for project ${projectName}'
        : 'Role assignment for ${principalId}'
    }
  }
]

@description('Array of created role assignment IDs')
output roleAssignmentIds array = [
  for (role, i) in roles: {
    roleId: role.id
    roleName: contains(role, 'name') ? role.name : role.id
    assignmentId: roleAssignment[i].id
  }
]

// @description('Project ID')
// output projectId string = project.id

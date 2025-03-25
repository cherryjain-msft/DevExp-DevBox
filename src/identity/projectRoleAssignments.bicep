targetScope = 'subscription'

@description('Role to assign to the identity.')
param roleAssignmentId string

@description('The principal ID of the identity to assign the roles to.')
param principalId string

@description('Project Identity Role Assignments')
resource projectIdentityRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(roleAssignmentId, principalId)
  scope: subscription()
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignmentId)
  }
}

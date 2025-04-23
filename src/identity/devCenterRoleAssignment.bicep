targetScope = 'subscription'

@description('The role definition ID to assign to the identity')
param id string

@description('The principal ID of the identity to assign the role to')
param principalId string

@description('The principal type of the identity to assign the role to')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param principalType string = 'ServicePrincipal'

@description('Existing role definition reference')
resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: id
  scope: subscription()
}

@description('Role assignment resource')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, id)
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinition.id
    principalType: principalType
  }
}

@description('The ID of the created role assignment')
output roleAssignmentId string = roleAssignment.id

@description('The scope of the role assignment')
output scope string = subscription().id

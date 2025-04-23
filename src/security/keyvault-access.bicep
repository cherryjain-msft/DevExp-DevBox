@description('This module configures access policies for an existing Azure Key Vault')
metadata description = 'Assigns an Azure Key Vault access policy.'

@description('The operation name for the access policy deployment (add, replace)')
@allowed([
  'add'
  'replace'
  'remove'
])
param name string = 'add'

@description('The name of the existing Key Vault')
param keyVaultName string

@description('The permissions to be assigned to the access policy')
param permissions object = {
  secrets: [
    'get'
    'list'
  ]
  keys: []
  certificates: []
  storage: []
}

@description('The principal ID (object ID) to be granted access to the Key Vault')
param principalId string

@description('Optional. Azure Active Directory tenant ID that should be used for authenticating requests to the key vault.')
param tenantId string = subscription().tenantId

@description('Reference to the existing Key Vault')
resource keyVault 'Microsoft.KeyVault/vaults@2024-12-01-preview' existing = {
  name: keyVaultName
}

@description('Key Vault Access Policies')
resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2024-12-01-preview' = {
  parent: keyVault
  name: name
  properties: {
    accessPolicies: [
      {
        objectId: principalId
        tenantId: tenantId
        permissions: permissions
      }
    ]
  }
}

@description('The ID of the Key Vault')
output keyVaultId string = keyVault.id

@description('The name of the Key Vault')
output keyVaultName string = keyVault.name

@description('The principal ID that was granted access')
output principalId string = principalId

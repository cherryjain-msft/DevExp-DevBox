metadata description = 'Assigns an Azure Key Vault access policy.'

@description('The name of the access policy.')
param name string = 'add'

@description('The name of the Key Vault.')
param keyVaultName string

@description('The permissions to be assigned to the access policy.')
param permissions object = { secrets: ['get', 'list'] }

@description('The principal ID to be granted access to the Key Vault.')
param principalId string

resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyVault
  name: name
  properties: {
    accessPolicies: [
      {
        objectId: principalId
        tenantId: subscription().tenantId
        permissions: permissions
      }
    ]
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

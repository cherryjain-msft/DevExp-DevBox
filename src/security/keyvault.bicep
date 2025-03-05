metadata description = 'Creates an Azure Key Vault.'

@description('The name of the Key Vault.')
param name string

@description('The location of the Key Vault.')
param location string = resourceGroup().location

@description('Tags to be applied to the Key Vault.')
param tags object = {}

@description('The principal ID to be granted access to the Key Vault.')
param principalId string

resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: '${name}-${uniqueString(resourceGroup().id, name, resourceGroup().name, subscription().id)}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        objectId: principalId
        permissions: {
          secrets: ['all']
          keys: ['all']
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

@description('The endpoint URI of the Key Vault.')
output endpoint string = keyVault.properties.vaultUri

@description('The name of the Key Vault.')
output name string = keyVault.name

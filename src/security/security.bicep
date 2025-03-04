@description('Key Vault Name')
param name string

@description('Key Vault Tags')
param tags object

@description('Secret Value')
@secure()
param secretValue string

module keyVault '../security/keyvault.bicep' = {
  name: 'keyvault'
  scope: resourceGroup()
  params: {
    name: name
    location: resourceGroup().location
    tags: tags
  }
}

module secret 'keyvault-secret.bicep' = {
  name: 'secret'
  params: {
    name: 'ghToken'
    keyVaultName: keyVault.name
    secretValue: secretValue
  }
}

output keyVaultName string = keyVault.name

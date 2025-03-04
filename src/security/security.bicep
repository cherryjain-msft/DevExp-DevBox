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
    principalId: deployer().objectId
    location: resourceGroup().location
    tags: tags
  }
}

module secret 'keyvault-secret.bicep' = {
  name: 'secret'
  params: {
    name: 'ghToken'
    keyVaultName: keyVault.outputs.name
    secretValue: secretValue
  }
}

output keyVaultName string = keyVault.outputs.name
output secretIdentifier string = secret.outputs.secretUri
output endpoint string = keyVault.outputs.endpoint

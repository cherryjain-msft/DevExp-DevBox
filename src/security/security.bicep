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

@description('Module to create a secret in the Key Vault')
module secret 'keyvault-secret.bicep' = {
  name: 'secret'
  scope: resourceGroup()
  params: {
    name: 'ghToken'
    keyVaultName: keyVault.outputs.name
    secretValue: secretValue
  }
}

@description('The name of the Key Vault')
output keyVaultName string = keyVault.outputs.name

@description('The identifier of the secret')
output secretIdentifier string = secret.outputs.secretUri

@description('The endpoint of the Key Vault')
output endpoint string = keyVault.outputs.endpoint

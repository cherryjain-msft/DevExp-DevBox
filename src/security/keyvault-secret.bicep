metadata description = 'Creates or updates a secret in an Azure Key Vault.'

@description('The name of the secret.')
param name string

@description('Tags to be applied to the secret.')
param tags object = {}

@description('The name of the Key Vault.')
param keyVaultName string

@description('The content type of the secret.')
param contentType string = 'string'

@description('The value of the secret. Provide only derived values like blob storage access, but do not hard code any secrets in your templates.')
@secure()
param secretValue string

@description('Specifies whether the secret is enabled.')
param enabled bool = true

@description('The expiration time of the secret in Unix time format.')
param exp int = 0

@description('The not-before time of the secret in Unix time format.')
param nbf int = 0

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: name
  tags: tags
  parent: keyVault
  properties: {
    attributes: {
      enabled: enabled
      exp: exp
      nbf: nbf
    }
    contentType: contentType
    value: secretValue
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

@description('The identifier of the secret.')
output secretIdentifier string = keyVaultSecret.id

@description('The URI of the secret.')
output secretUri string = keyVaultSecret.properties.secretUri

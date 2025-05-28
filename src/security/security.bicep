@description('Key Vault Tags')
param tags object

@description('Secret Value')
@secure()
param secretValue string

@description('Log Analytics Workspace ID')
param logAnalyticsId string

@description('Azure Key Vault Configuration')
var securitySettings = loadYamlContent('../../infra/settings/security/security.yaml')

@description('Azure Key Vault')
module keyVault 'keyVault.bicep' = if (securitySettings.create) {
  params: {
    tags: {}
    keyvaultSettings: securitySettings
  }
}

@description('Existing Key Vault')
resource existingKeyVault 'Microsoft.KeyVault/vaults@2024-12-01-preview' existing = if (!securitySettings.create) {
  name: securitySettings.keyVault.name
  scope: resourceGroup()
}

@description('Key vault secret module')
module secret 'secret.bicep' = {
  params: {
    name: securitySettings.keyVault.secretName
    keyVaultName: (securitySettings.create ? keyVault.outputs.keyVaultName : existingKeyVault.name)
    logAnalyticsId: logAnalyticsId
    secretValue: secretValue
  }
}
@description('The name of the Key Vault')
output keyVaultName string = (securitySettings.create ? keyVault.outputs.keyVaultName : existingKeyVault.name)

@description('The identifier of the secret')
output secretIdentifier string = secret.outputs.secretIdentifier

@description('The endpoint URI of the Key Vault')
output endpoint string = (securitySettings.create ? keyVault.outputs.endpoint : existingKeyVault.properties.vaultUri)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, deployer().objectId, '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
  properties: {
    principalId: deployer().objectId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
  }
  dependsOn: [
    keyVault
    secret
  ]
}

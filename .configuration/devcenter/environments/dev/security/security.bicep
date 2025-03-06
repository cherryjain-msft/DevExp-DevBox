@description('Log Analytics Workspace')
param logAnalyticsWorkspaceId string

module keyvault 'keyvault.bicep' = {
  scope: resourceGroup()
  name: 'keyvault'
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

@description('The name of the Key Vault')
output keyVaultName string = keyvault.outputs.keyVaultName

@description('The identifier of the secret')
output secretIdentifier string = keyvault.outputs.secretIdentifier

@description('The endpoint URI of the Key Vault.')
output endpoint string = keyvault.outputs.endpoint

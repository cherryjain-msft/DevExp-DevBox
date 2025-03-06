@description('Key Vault Name')
var keyVaultName = 'identity'

@description('Secret Name')
var secretName = 'gha'

@description('Log Analytics Workspace')
param logAnalyticsWorkspaceId string

@description('Secret Value')
var secretValue = 'example-secret-value'

param name2 string = utcNow('yyyyMMddHHmmss')

var uniqueName = guid('${keyVaultName}',subscription().displayName,subscription().id, resourceGroup().id,secretName, name2)

resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: '${keyVaultName}-${uniqueString(resourceGroup().id, keyVaultName, resourceGroup().name, uniqueName)}'
  location: resourceGroup().location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        objectId: deployer().objectId
        permissions: {
          secrets: ['all']
          keys: ['all']
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

@description('Log Analytics Diagnostic Settings')
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'keyvault'
  scope: keyVault
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: secretName
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
      exp: 0
      nbf: 0
    }
    contentType: 'string'
    value: secretValue
  }
}

@description('The name of the Key Vault')
output keyVaultName string = keyVault.name

@description('The identifier of the secret')
output secretIdentifier string = secret.properties.secretUri

@description('The endpoint URI of the Key Vault.')
output endpoint string = keyVault.properties.vaultUri

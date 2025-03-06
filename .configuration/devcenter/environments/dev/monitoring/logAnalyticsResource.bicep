@description('Name of the Log Analytics workspace')
param name string

@description('Tags for the Log Analytics workspace')
param tags object = {}

@description('Log Analytics workspace SKU')
@allowed([
  'Free'
  'PerGB2018'
  'Standalone'
  'CapacityReservation'
])
param logAnalyticsSku string = 'PerGB2018'

@description('Create a Log Analytics workspace')
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${name}-${uniqueString(name, resourceGroup().id)}'
  location: resourceGroup().location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: logAnalyticsSku
    }
  }
}

@description('Log Analytics Diagnostic Settings')
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'keyvault'
  scope: logAnalytics
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
    workspaceId: logAnalytics.id
  }
}

@description('Create an Application Insights resource')
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${name}-${uniqueString(name, resourceGroup().id)}'
  location: resourceGroup().location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString
output workspaceId string = logAnalytics.id

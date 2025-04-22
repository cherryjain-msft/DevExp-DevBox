@description('The name of the Log Analytics Workspace')
@minLength(3)
@maxLength(24)
param name string

@description('The Azure region for the Log Analytics Workspace')
param location string = resourceGroup().location

@description('The number of days to retain data in the workspace')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Tags to apply to the Log Analytics Workspace')
param tags object = {}

@description('The SKU of the Log Analytics Workspace')
@allowed([
  'PerGB2018'
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param sku string = 'PerGB2018'

@description('Log Analytics Workspace')
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${name}-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('Log Analytics Diagnostic Settings')
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${logAnalyticsWorkspace.name}-diagnostics'
  scope: logAnalyticsWorkspace
  properties: {
    workspaceId: logAnalyticsWorkspace.id
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
  }
}

@description('The resource ID of the Log Analytics Workspace')
output workspaceId string = logAnalyticsWorkspace.id

@description('The resource ID of the Log Analytics Workspace')
output logAnalyticsId string = logAnalyticsWorkspace.id

@description('The name of the Log Analytics Workspace')
output logAnalyticsName string = logAnalyticsWorkspace.name

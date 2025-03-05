@description('The name of the Log Analytics Workspace')
param name string

@description('Log Analytics Workspace')
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: '${name}-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

@description('The ID of the Log Analytics Workspace')
output workspaceId string = logAnalyticsWorkspace.id

@description('The ID of the Log Analytics Workspace')
output logAnalyticsId string = logAnalyticsWorkspace.id

@description('The name of the Log Analytics Workspace')
output logAnalyticsName string = logAnalyticsWorkspace.name

@description('Log Analytics Diagnostic Settings')
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: logAnalyticsWorkspace.name
  scope: logAnalyticsWorkspace
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
    workspaceId: logAnalyticsWorkspace.id
  }
}

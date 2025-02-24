@allowed([
  'vNet'
  'devcenter'
  'loganalytics'
])
param resourceType string

param resourceName string

param workspaceId string

resource vnet 'Microsoft.ScVmm/virtualNetworks@2024-06-01' existing = if (resourceType == 'vNet') {
  name: resourceName
}

resource devcenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' existing = if (resourceType == 'devcenter') {
  name: resourceName
}

resource loganalytics 'Microsoft.OperationalInsights/workspaces@2020-10-01' existing = if (resourceType == 'loganalytics') {
  name: resourceName
}

@description('Network Diagnostic Settings')
resource logAnalyticsDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'virtualNetwork-DiagnosticSettings'
  scope: (resourceType == 'vNet') ? vnet : (resourceType == 'devcenter') ? devcenter : loganalytics
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
    workspaceId: workspaceId
  }
}

output diagnosticSettingsId string = logAnalyticsDiagnosticSettings.id
output diagnosticSettingsName string = logAnalyticsDiagnosticSettings.name
output diagnosticSettingsType string = logAnalyticsDiagnosticSettings.type

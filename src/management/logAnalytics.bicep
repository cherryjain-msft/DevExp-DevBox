param name string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: name
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

output workspaceId string = logAnalyticsWorkspace.id
output logAnalyticsId string = logAnalyticsWorkspace.id
output logAnalyticsName string = logAnalyticsWorkspace.name

module logAnalyticsDiagnostics 'diagnosticSettings.bicep' = {
  name: 'logAnalyticsDiagnostics'
  params: {
    resourceType: 'loganalytics'
    resourceName: logAnalyticsWorkspace.name
    workspaceId: logAnalyticsWorkspace.id
  }
}

output diagnosticSettingsId string = logAnalyticsDiagnostics.outputs.diagnosticSettingsId
output diagnosticSettingsName string = logAnalyticsDiagnostics.outputs.diagnosticSettingsName
output diagnosticSettingsType string = logAnalyticsDiagnostics.outputs.diagnosticSettingsType

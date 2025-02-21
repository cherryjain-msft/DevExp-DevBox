@description('Solution Name')
param name string

module logAnalytics './logAnalytics.bicep' = {
  name: 'logAnalytics'
  scope: resourceGroup()
  params: {
    name: '${name}-${uniqueString(resourceGroup().id)}'
  }
}

output logAnalyticsId string = logAnalytics.outputs.workspaceId
output logAnalyticsName string = logAnalytics.name

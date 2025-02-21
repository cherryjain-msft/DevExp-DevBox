@description('The name of the Log Analytics workspace.')
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

@description('The ID of the Log Analytics workspace.')
output workspaceId string = logAnalyticsWorkspace.id

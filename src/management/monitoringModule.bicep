targetScope = 'subscription'

@description('Landing Zone')
param landingZone object

@description('Connectivity Resource Group')
resource managementResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.create) {
  name: landingZone.name
  location: 'easus2'
  tags: {}
}

module logAnalytics  'logAnalytics.bicep' = {
  scope: managementResourceGroup
  name: 'logAnalitycs'
  params: {
    name: landingZone.logAnalyticsName
  }
}

output logAnalyticsId string = logAnalytics.outputs.logAnalyticsId
output logAnalyticsName string = logAnalytics.outputs.logAnalyticsName

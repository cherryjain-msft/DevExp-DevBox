targetScope = 'subscription'

@description('Location for the deployment')
param location string

@description('Landing Zone')
param landingZone object

@description('Connectivity Resource Group')
resource managementResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.create) {
  name: landingZone.name
  location: location
  tags: {}
}

var resourceGroupName = landingZone.create ? managementResourceGroup.name : landingZone.name

module logAnalytics 'logAnalytics.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'logAnalitycs'
  params: {
    name: landingZone.logAnalyticsName
  }
}

output managementResourceGroupName string = (landingZone.create ? managementResourceGroup.name : landingZone.name)
output logAnalyticsId string = logAnalytics.outputs.logAnalyticsId
output logAnalyticsName string = logAnalytics.outputs.logAnalyticsName

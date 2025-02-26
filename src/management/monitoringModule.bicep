targetScope = 'subscription'

@description('Environment Name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string 

@description('Location for the deployment')
param location string

@description('Landing Zone')
param landingZone object

param formattedDateTime string = utcNow()

@description('Connectivity Resource Group')
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.create) {
  name: '${landingZone.name}-${environmentName}-rg'
  location: location
  tags: landingZone.tags
}

var resourceGroupName = landingZone.create ? resourceGroup.name : landingZone.name

module logAnalytics 'logAnalytics.bicep' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'logAnalitycs-${formattedDateTime}'
  params: {
    name: landingZone.logAnalyticsName
  }
}

output managementResourceGroupName string = (landingZone.create ? resourceGroup.name : landingZone.name)
output logAnalyticsId string = logAnalytics.outputs.logAnalyticsId
output logAnalyticsName string = logAnalytics.outputs.logAnalyticsName

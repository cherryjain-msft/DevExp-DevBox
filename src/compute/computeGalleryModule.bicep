targetScope = 'subscription'

@description('Environment Name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string 

@description('Location for the deployment')
param location string

@description('Landing Zone Information')
param landingZone object

param formattedDateTime string = utcNow()

var settings = loadJsonContent('../../infra/settings/compute/settings.json')

@description('Resource Group')
resource coputeResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.create) {
  name: '${landingZone.name}-${environmentName}-rg'
  location: location
  tags: landingZone.tags
}

var resourceGroupName = landingZone.create ? coputeResourceGroup.name : landingZone.name

@description('Compute Gallery')
module computeGallery 'computeGallery.bicep' = {
  name: 'computeGallery-${formattedDateTime}'
  scope: resourceGroup(resourceGroupName)
  params: {
    settings: settings
  }
}

output computeResourceGroupName string = (landingZone.create ? coputeResourceGroup.name : landingZone.name)
output computeGalleryName string = computeGallery.outputs.computeGalleryName
output computeGalleryId string = computeGallery.outputs.computeGalleryId

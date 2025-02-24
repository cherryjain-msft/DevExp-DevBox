targetScope = 'subscription'

@description('Location for the deployment')
param location string

@description('Landing Zone Information')
param landingZone object

param formattedDateTime string = utcNow()

var settings = loadJsonContent('../../infra/settings/computegallery/settings.json')

@description('Resource Group')
resource imageGalleryResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.create) {
  name: landingZone.name
  location: location
}

var resourceGroupName = landingZone.create ? imageGalleryResourceGroup.name : landingZone.name

@description('Compute Gallery')
module computeGallery 'computeGallery.bicep' = {
  name: 'computeGallery-${formattedDateTime}'
  scope: resourceGroup(resourceGroupName)
  params: {
    settings: settings
  }
}

output computeGalleryId string = computeGallery.outputs.computeGalleryId
output computeGalleryName string = computeGallery.outputs.computeGalleryName

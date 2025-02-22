targetScope = 'subscription'

@description('Location for the deployment')
param location string

@description('Landing Zone Information')
param landingZone object

var networkSettings = loadJsonContent('../../infra/settings/connectivity/settings.json')

@description('Resource Group')
resource imageGalleryResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if (landingZone.create) {
  name: landingZone.name
  location: location
}

@description('Existing Resource Group')
resource existingImageGalleryResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!landingZone.create) {
  name: landingZone.name
}

var resourceGroupName = landingZone.create ? imageGalleryResourceGroup.name : landingZone.name



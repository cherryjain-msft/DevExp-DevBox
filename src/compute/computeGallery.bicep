@description('Compute Gallery Name')
param settings ComputeSettings

param location string = resourceGroup().location

type ComputeSettings = {
  name: string
  tags: object
}

@description('Compute Gallery')
resource computeGallery 'Microsoft.Compute/galleries@2024-03-03' = {
  name: settings.name
  location: location
}

output computeGalleryId string = computeGallery.id
output computeGalleryName string = computeGallery.name

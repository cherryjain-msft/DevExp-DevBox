@description('Compute Gallery Name')
param settings ComputeSettings

type ComputeSettings = {
  name: string
  tags: object
}

@description('Compute Gallery')
resource computeGallery 'Microsoft.Compute/galleries@2024-03-03' = {
  name: '${settings.name}-${uniqueString(settings.name, resourceGroup().id)}'
  location: resourceGroup().location
  tags: settings.tags
  properties: {
    description: 'Dev Center Compute Gallery'
  }
}

output computeGalleryId string = computeGallery.id
output computeGalleryName string = computeGallery.name

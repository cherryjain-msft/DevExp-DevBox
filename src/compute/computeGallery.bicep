@description('Compute Gallery Name')
param settings ComputeSettings

type ComputeSettings = {
  name: string
  create: bool
  tags: object
}

@description('Compute Gallery')
resource computeGallery 'Microsoft.Compute/galleries@2024-03-03' = if (settings.create) {
  name: '${settings.name}${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  tags: settings.tags
  properties: {
    description: 'Dev Center Compute Gallery'
  }
}

output computeGalleryId string = computeGallery.id
output computeGalleryName string = computeGallery.name

@description('Compute Gallery Name')
param settings object

@description('Compute Gallery')
resource computeGallery 'Microsoft.Compute/galleries@2024-03-03' = if (settings.computeGallery.create) {
  name: '${settings.name}${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  tags: settings.tags
  properties: {
    description: 'Dev Center Compute Gallery'
  }
}

@description('Compute Gallery ID')
output computeGalleryId string = computeGallery.id

@description('Compute Gallery Name')
output computeGalleryName string = computeGallery.name

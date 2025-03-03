@description('Dev Center Compute Gallery')
param computeGalleryName string

@description('Compute Gallery ID')
param computeGalleryId string

@description('DevCenter Resource')
param devCenterName string

resource devCenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' = {
  name: devCenterName
  location: resourceGroup().location
}

@description('DevCenter Compute Gallery')
resource devCenterGallery 'Microsoft.DevCenter/devcenters/galleries@2024-10-01-preview' = {
  name: computeGalleryName
  parent: devCenter
  properties: {
    galleryResourceId: computeGalleryId
  }
}

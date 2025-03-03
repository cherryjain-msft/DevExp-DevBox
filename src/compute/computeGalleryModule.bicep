var settings = loadJsonContent('../../infra/settings/compute/settings.json')

@description('Compute Gallery')
module computeGallery 'computeGallery.bicep' = {
  name: 'computeGallery'
  scope: resourceGroup()
  params: {
    settings: settings
  }
}

output computeGalleryName string = computeGallery.outputs.computeGalleryName
output computeGalleryId string = computeGallery.outputs.computeGalleryId

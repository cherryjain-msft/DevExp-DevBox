var settings = loadYamlContent('../../infra/settings/compute/computeGallery.yaml')

@description('Compute Gallery')
module computeGallery 'computeGallery.bicep' = {
  name: 'computeGallery'
  params: {
    settings: {
      name: settings.name
      tags: settings.tags
    }
  }
}

output computeGalleryName string = computeGallery.outputs.computeGalleryName
output computeGalleryId string = computeGallery.outputs.computeGalleryId

@description('DevBox Definition Name')
param name string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('DevCenter Name')
param devCenterName string

@description('Hibernate Support')
@allowed([
  'Enabled'
  'Disabled'
])
param hibernateSupport string

@description('Image Name')
param imageName string

@description('SKU')
param sku string

@description('Storage Type')
@allowed([
  'ssd_128gb'
  'ssd_256gb'
  'ssd_512gb'
  'ssd_1tb'
])
param osStorageType string 

@description('DevCenter Resource')
resource devCenter 'Microsoft.DevCenter/devcenters@2024-10-01-preview' existing = {
  name: devCenterName
}

@description('DevBox Definition Resource')
resource devBoxDefinition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2024-10-01-preview' = {
  name: name
  parent: devCenter
  location: location
  properties: {
    hibernateSupport: hibernateSupport
    imageReference: {
      id: '${resourceId('Microsoft.DevCenter/devcenters/galleries',devCenter.name,'Default')}/images/${imageName}'
    }
    sku: {
      name: sku
    }
    osStorageType: osStorageType
  }
}

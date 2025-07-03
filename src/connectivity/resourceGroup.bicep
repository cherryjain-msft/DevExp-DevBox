targetScope = 'subscription'

param create bool

@secure()
param name string

@description('Environment name used for resource naming (dev, test, prod)')
@minLength(2)
@maxLength(10)
param environmentName string

param location string

param tags object

var resourceGroupName = (create ? '${name}-${environmentName}-${location}-rg' : name)

@description('Resource group name for new or existing resource group')
resource newRg 'Microsoft.Resources/resourceGroups@2025-04-01' = if (create) {
  name: resourceGroupName
  location: location
  tags: tags
}
@description('Reference to existing resource group')
resource existingRg 'Microsoft.Resources/resourceGroups@2025-04-01' existing = if (!create) {
  name: name
}

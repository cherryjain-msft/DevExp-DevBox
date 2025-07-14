targetScope = 'subscription'

param create bool

@description('Name of the resource group')
param name string

param location string

param tags object

@description('Resource group name for new or existing resource group')
resource newRg 'Microsoft.Resources/resourceGroups@2025-04-01' = if (create) {
  name: name
  location: location
  tags: tags
}

@description('Reference to existing resource group')
resource existingRg 'Microsoft.Resources/resourceGroups@2025-04-01' existing = if (!create) {
  name: name
}

output resourceGroupName string = create ? newRg.name : existingRg.name

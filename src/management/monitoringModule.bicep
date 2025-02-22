targetScope = 'subscription'

@description('Solution Name')
param name string

@description('Connectivity Resource Group')
resource managementResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = if (true) {
  name: name
  location: 'easus2'
  tags: {}
}

module logAnalytics  'logAnalytics.bicep' = {
  scope: managementResourceGroup
  name: 'log'
  params: {
    name: 'logAnalytics'
  }
}

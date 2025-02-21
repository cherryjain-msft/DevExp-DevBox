targetScope = 'subscription'

@description('Workload Name')
param workloadName string

@description('Location for the deployment')
param location string

@description('Landing Zone Information')
param landingZone object

@description('Deployment Environment')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('Connectivity Resource Group')
resource connectivityResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.connectivity.create) {
  name: '${workloadName}-${landingZone.connectivity.name}-${environment}'
  location: location
  tags: landingZone.connectivity.tags
}

output connectivityResourceGroupName string = (landingZone.connectivity.create)
  ? connectivityResourceGroup.name
  : landingZone.connectivity.name

output connectivityResourceGroupId string = (landingZone.connectivity.create) ? connectivityResourceGroup.id : 'N/A'

@description('Connectivity Resource Group')
resource managementResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.management.create) {
  name: '${workloadName}-${landingZone.management.name}-${environment}'
  location: location
  tags: landingZone.management.tags
}

output managementResourceGroupId string = (landingZone.management.create) ? managementResourceGroup.id : 'N/A'

output managementResourceGroupName string = (landingZone.management.create)
  ? managementResourceGroup.name
  : landingZone.management.name

@description('Connectivity Resource Group')
resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = if (landingZone.workload.create) {
  name: '${workloadName}-${landingZone.workload.name}-${environment}'
  location: location
  tags: landingZone.workload.tags
}

output workloadResourceGroupId string = (landingZone.workload.create) ? workloadResourceGroup.id : 'N/A'

output workloadResourceGroupName string = (landingZone.workload.create)
  ? workloadResourceGroup.name
  : landingZone.workload.name

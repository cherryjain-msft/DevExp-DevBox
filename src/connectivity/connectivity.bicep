targetScope = 'subscription'
// @description('Name of the DevCenter instance')
// param devCenterName string

@description('Project Network Connectivity')
param projectNetwork object

@description('Log Analytics workspace resource ID for diagnostic settings')
param logAnalyticsId string

@description('Azure region for resource deployment')
param location string

@description('Environment name used for resource naming (dev, test, prod)')
@minLength(2)
@maxLength(10)
param environmentName string

module virtualNetwork 'vnet.bicep' = {
  name: 'virtualNetwork-${uniqueString(projectNetwork.name, location)}'
  scope: subscription()
  params: {
    logAnalyticsId: logAnalyticsId
    environmentName: environmentName
    location: location
    settings: {
      name: projectNetwork.name
      virtualNetworkType: projectNetwork.virtualNetworkType
      create: projectNetwork.create
      resourceGroupName: projectNetwork.resourceGroupName
      addressPrefixes: projectNetwork.addressPrefixes
      subnets: projectNetwork.subnets
      tags: projectNetwork.tags
    }
  }
}

// module networkConnection './networkConnection.bicep' = if (projectNetwork.create && projectNetwork.virtualNetworkType == 'Unmanaged') {
//   name: 'networkConnection-${uniqueString(projectNetworkRg.id)}'
//   scope: projectNetworkRg
//   params: {
//     devCenterName: devCenterName
//     name: 'netconn-${virtualNetwork.name}'
//     subnetId: virtualNetwork.outputs.AZURE_VIRTUAL_NETWORK.subnets[0].id
//   }
// }

// var connectionName = (projectNetwork.create && projectNetwork.virtualNetworkType == 'Unmanaged')
//   ? networkConnection.name
//   : projectNetwork.name

// output networkConnectionName string = connectionName

// output networkType string = projectNetwork.virtualNetworkType

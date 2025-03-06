@description('The name of the workload')
param workloadName string

@description('App Service Environment')
@allowed([
  'dev'
  'prod'
])
param environment string

param keyVaultName string

@secure()
@description('Instrumentation Key for Application Insights')
param instrumentationKey string

@secure()
@description('Connection String for Application Insights')
param connectionString string

param logAnalyticsWorkspaceId string

module webapp 'appServiceResource.bicep' = {
  name: 'webapp'
  scope: resourceGroup()
  params: {
    name: workloadName
    environment: environment
    keyVaultName: keyVaultName
    instrumentationKey: instrumentationKey
    connectionString: connectionString
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

output webAppName string = webapp.outputs.webAppName
output webAppUrl string = webapp.outputs.webAppUrl

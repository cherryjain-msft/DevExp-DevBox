@description('The name of the workload')
var workloadName = 'identityProvider'

@description('Location for the resources')
param location string = resourceGroup().location

@description('The environment for the deployment')
@allowed([
  'dev'
  'prod'
])
param environment string = 'dev'

@description('Module for Log Analytics and Application Insights')
module monitoring 'monitoring/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup()
  params: {
    workloadName: workloadName
    environment: environment
  }
}

module security 'security/security.bicep' = {
  scope: resourceGroup()
  name: 'security'
  params: {
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
  }
}

@description('Module for App Service')
module workload 'core/webapp.bicep' = {
  name: 'workload'
  scope: resourceGroup()
  params: {
    workloadName: workloadName
    environment: environment
    keyVaultName: security.outputs.keyVaultName
    instrumentationKey: monitoring.outputs.instrumentationKey
    connectionString: monitoring.outputs.connectionString
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
  }
}

@description('Output the name of the web app')
output resourceName string = workload.outputs.webAppName

@description('Output the URL of the web app')
output webAppUrl string = workload.outputs.webAppUrl

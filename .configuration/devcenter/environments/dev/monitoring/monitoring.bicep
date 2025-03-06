@description('The name of the workload')
param workloadName string

@description('The environment for the deployment')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Module for Log Analytics and Application Insights')
module logAnalytics 'logAnalyticsResource.bicep' = {
  name: 'logAnalytics'
  scope: resourceGroup()
  params: {
    name: '${workloadName}-loganalytics'
    tags: {
      environment: environment
      name: workloadName
    }
  }
}

output workspaceId string = logAnalytics.outputs.workspaceId
output connectionString string = logAnalytics.outputs.connectionString
output instrumentationKey string = logAnalytics.outputs.instrumentationKey

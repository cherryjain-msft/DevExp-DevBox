@description('App Service Name')
param name string

@description('App Service Environment')
@allowed([
  'dev'
  'prod'
])
param environment string

param keyVaultName string

@description('App Service Kind')
@allowed([
  'app'
  'app,linux'
  'app,linux,container'
  'hyperV'
  'app,container,windows'
  'app,linux,kubernetes'
  'app,linux,container,kubernetes'
  'functionapp'
  'functionapp,linux'
  'functionapp,linux,container,kubernetes'
  'functionapp,linux,kubernetes'
])
param kind string = 'app,linux'

@description('App Service Plan SKU')
param sku object = {
  name: 'P1V3'
  tier: 'PremiumV3'
  capacity: 1
}

@description('App Service Current Stack')
@allowed([
  'dotnetcore'
  'java'
  'node'
  'php'
])
param currentStack string = 'dotnetcore'

@description('Dotnet Core Version')
@allowed([
  '7.0'
  '8.0'
  '9.0'
])
param dotnetcoreVersion string = '9.0'

@secure()
@description('Instrumentation Key for Application Insights')
param instrumentationKey string

@secure()
@description('Connection String for Application Insights')
param connectionString string

@description('App Settings')
param appSettings array = [
  {
    name: 'ASPNETCORE_ENVIRONMENT'
    value: 'Development'
  }
  {
    name: 'PLATFORM_ENGINEERING_ENVIRONMENT'
    value: 'Development'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: instrumentationKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: connectionString
  }
  {
    name: 'APPINSIGHTS_PROFILERFEATURE_VERSION'
    value: '1.0.0'
  }
  {
    name: 'APPINSIGHTS_SNAPSHOTFEATURE_VERSION'
    value: '1.0.0'
  }
  {
    name: 'APPLICATIONINSIGHTS_ENABLESQLQUERYCOLLECTION'
    value: 'enabled'
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~3'
  }
  {
    name: 'DiagnosticServices_EXTENSION_VERSION'
    value: '~3'
  }
  {
    name: 'IdProviderTemplate'
    value: '2.0'
  }
]

param logAnalyticsWorkspaceId string

@description('Tags')
param tags object = {}

@description('LinuxFxVersion')
var linuxFxVersion = contains(kind, 'linux') ? '${toUpper(currentStack)}|${dotnetcoreVersion}' : null

@description('App Service Plan Resource')
resource servicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: '${name}-${uniqueString(resourceGroup().id, name)}-svcplan'
  location: resourceGroup().location
  sku: sku
  kind: 'linux'
  properties: {
    reserved: contains(kind, 'linux') ? true : false
    elasticScaleEnabled: true
  }

  tags: tags
}

@description('Log Analytics Diagnostic Settings')
resource spDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'appsplan'
  scope: servicePlan
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

@description('App Service Resource')
resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: '${name}-webapp-${environment}'
  location: resourceGroup().location
  kind: kind
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: servicePlan.id
    enabled: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: true
      preWarmedInstanceCount: 1
      http20Enabled: true
      appSettings: appSettings
      
    }
  }
}

@description('Log Analytics Diagnostic Settings')
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'keyvault'
  scope: webApp
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

module keyvaultAccess '../security/keyvault-access.bicep' = {
  name: 'keyvault-access'
  params: {
    keyVaultName: keyVaultName
    principalId: webApp.identity.principalId
  }
}

output webAppName string = webApp.name
output webAppUrl string = webApp.properties.defaultHostName

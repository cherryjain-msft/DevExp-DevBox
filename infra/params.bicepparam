using 'main.bicep'

@allowed(['dev', 'staging', 'prod'])
param environmentName = 'dev'

param formattedDateTime = ''

param location = 'eastus2'

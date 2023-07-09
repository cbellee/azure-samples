@description('Specifies the region of all resources. Defaults to location of resource group')
param location string = resourceGroup().location

@description('Name of the application. Used as a suffix for resources')
param applicationName string = uniqueString(resourceGroup().id)

@description('The SKU for the storage account')
param storageSku string = 'Standard_LRS'

@description('Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 2147483647. Multi Region: 100000 to 2147483647.')
@minValue(10)
@maxValue(2147483647)
param maxStalenessPrefix int = 100000

@description('Max lag time (seconds). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
@minValue(5)
@maxValue(86400)
param maxIntervalInSeconds int = 300

@description('Maximum autoscale throughput for the database shared with up to 25 collections')
@minValue(1000)
@maxValue(1000000)
param sharedAutoscaleMaxThroughput int = 1000

@description('The name for the first Mongo DB collection')
param collectionName string = 'TodoItems'

@description('The name for the Mongo DB database')
param cosmosDbName string = 'TodoDB'

var storageAccountName = 'fnstor${replace(applicationName, '-', '')}'
var appInsightsName = '${applicationName}-ai'
var appServicePlanName = '${applicationName}-asp'
var workspaceName = '${applicationName}-wks'
var cosmosDbAccountName = '${applicationName}db'
var functionAppName = '${applicationName}-fa'
var functionRuntime = 'dotnet'

var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  kind: 'elastic'
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  properties: {
    maximumElasticWorkerCount: 20
    reserved: true // linux
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosDbAccountName
  location: location
  kind: 'MongoDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    consistencyPolicy: consistencyPolicy
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2023-04-15' = {
  parent: cosmosAccount
  name: cosmosDbName
  properties: {
    resource: {
      id: cosmosDbName
    }
    options: {
      autoscaleSettings: {
        maxThroughput: sharedAutoscaleMaxThroughput
      }
    }
  }
}

resource collection 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases/collections@2023-04-15' = {
  parent: database
  name: collectionName
  properties: {
    resource: {
      id: collectionName
/*       shardKey: {
        id: 'Hash'
      } */
      indexes: [
        {
          key: {
            keys: [
              '_id'
            ]
          }
        }
      ]
    }
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsights.properties.InstrumentationKey}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionRuntime
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'cosmosDbAccount'
          value: cosmosAccount.name
        }
        {
          name: 'collection'
          value: collection.name
        }
        {
          name: 'db'
          value: database.name
        }
        {
          name: 'port'
          value: '10255'
        }
        {
          name: 'cosmosMongoSuffix'
          value: 'mongo.cosmos.azure.com'
        }
        {
          name: 'subscriptionId'
          value: subscription().subscriptionId
        }
        {
          name: 'resourceGroup'
          value: resourceGroup().name
        }
        {
          name: 'cosmosDbAccountResourceId'
          value: cosmosAccount.id
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: 'true'
        }
      ]
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource cosmosDbOperatorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'cosmosDbOperatorRoleAssignment')
  scope: cosmosAccount
  properties: {
    principalId: functionApp.identity.principalId
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/230815da-be43-4aae-9cb4-875f7bd000aa'
    principalType: 'ServicePrincipal'
  }
}

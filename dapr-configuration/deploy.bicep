param location string
param appName string
param imageName string
param acrName string

var prefix = uniqueString(resourceGroup().id)
var wksName = '${prefix}-wks'
var appConfigName = '${prefix}-app-config'
var acrMidName = '${prefix}-acr-mid'
var configMidName = '${prefix}-config-mid'
var acaEnvName = '${prefix}-aca-env'
var acrPullDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
var appConfigDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/516239f1-63e1-4d78-a4de-a74fb236a071'

resource configMid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: configMidName
  location: location
}

resource acrMid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: acrMidName
  location: location
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.name, 'acrPullRoleAssignment', prefix)
  scope: acr
  properties: {
    principalId: acrMid.properties.principalId
    roleDefinitionId: acrPullDefinitionId
    principalType: 'ServicePrincipal'
  }
}

resource appConfigReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appConfig.name, 'appConfigReaderRoleAssignment', prefix)
  scope: appConfig
  properties: {
    principalId: configMid.properties.principalId
    roleDefinitionId: appConfigDefinitionId
    principalType: 'ServicePrincipal'
  }
}

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: wksName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: appConfigName
  location: location
  sku: {
    name: 'Standard'
  }
}

resource appConfigItem1 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = {
  name: 'orderId1'
  parent: appConfig
  properties: {
    contentType: 'application/vnd.microsoft.appconfig.keyvalue'
    value: '1000'
  }
}

resource appConfigItem2 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = {
  name: 'orderId2'
  parent: appConfig
  properties: {
    contentType: 'application/vnd.microsoft.appconfig.keyvalue'
    value: '2000'
  }
}

resource acaEnvironment 'Microsoft.App/managedEnvironments@2023-04-01-preview' = {
  name: acaEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wks.properties.customerId
        sharedKey: wks.listKeys().primarySharedKey
      }
    }
  }
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-04-01-preview' = {
  name: 'configstore'
  parent: acaEnvironment
  properties: {
    componentType: 'configuration.azure.appconfig'
    version: 'v1'
    metadata: [
      {
        name: 'host'
        value: 'https://${appConfigName}.azconfig.io'
      }
      {
        name: 'azureClientId'
        value: configMid.properties.clientId
      }
    ]
    secrets: []
    scopes: []
  }
}

resource daprApp 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: appName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${acrMid.id}': {}
      '${configMid.id}': {}
    }
  }
  properties: {
    environmentId: acaEnvironment.id
    template: {
      containers: [
        {
          name: appName
          image: imageName
        }
      ]
      scale: {
        maxReplicas: 5
        minReplicas: 1
      }
    }
    configuration: {
      dapr: {
        appId: appName
        appPort: 8080
        appProtocol: 'http'
        enabled: true
        logLevel: 'debug'
        enableApiLogging: true
      }
      ingress: {
        external: true
        transport: 'http'
        targetPort: 8080
      }
      registries: [
        {
          identity: acrMid.id
          server: '${acr.name}.azurecr.io'
        }
      ]
    }
  }
}

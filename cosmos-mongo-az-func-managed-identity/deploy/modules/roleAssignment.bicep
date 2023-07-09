@description('The name of the Cosmos DB account that we will use for SQL Role Assignments')
param cosmosDbAccountName string

param mongoDbName string

@description('The Principal Id of the Function App that we will grant the role assignment to.')
param functionAppPrincipalId string

var roleDefinitionId = guid('mongodb-role-definition-', functionAppPrincipalId, cosmosDbAccount.id)
var roleAssignmentId = guid(roleDefinitionId, functionAppPrincipalId, cosmosDbAccount.id)
var roleDefinitionName = 'Function Read Write Role'

/* var dataActions = [
  'Microsoft.DocumentDB/databaseAccounts/readMetadata'
  'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
] */

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-11-15-preview' existing = {
  name: cosmosDbAccountName
}

resource mongoDbRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/mongodbRoleDefinitions@2023-04-15' = {
  name: '${cosmosDbAccountName}/${roleDefinitionId}'
  properties: {
    roleName: roleDefinitionName
    type: 'CustomRole'
    databaseName: mongoDbName
    privileges: [
      {
        actions: [
          '*'
        ]
        resource: {
          collection: '*'
          db: '*'
        }
      }
    ]
    roles: [
      {
        db: '*'
        role: 'readWrite'
      }
    ]
    /* assignableScopes: [
      cosmosDbAccount.id
    ]
    permissions: [
      {
        dataActions: dataActions
      }
    ] */
  }
  dependsOn: [
    cosmosDbAccount
  ]
}

resource sqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2021-11-15-preview' = {
  name: '${cosmosDbAccountName}/${roleAssignmentId}'
  properties: {
    roleDefinitionId: mongoDbRoleDefinition.id
    principalId: functionAppPrincipalId
    scope: cosmosDbAccount.id
  }
}

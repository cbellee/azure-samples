# Authenticate Azure function calls to Azure CosmosDB Mongo API using a managed identity

This sample shows you how you can use System-Assigned Managed Identities to authenticate calls between and Azure function and Azure Cosmos DB Mongo API database. The Azure Cosmos MongoDB API doesn't currently support obtaining a database connection string using managed identity, so this sample uses the function's managed identity to obtain the CosmosDB access key and builds the connection string.

To allow the function app to access the CosmosDB account, the script creates a Custom RBAC role with the listKeys permission on the CosmosDB account. The function app's system assigned managed identity is then assigned this role.

## Prerequisites

- Azure Subscription
- Azure CLI
- Bash shell (WSL, Git Bash, etc.)
- VS Code

## Deployment

- Clone this repo & open in VSCode
- Change working directory to 'deploy'
  - `$ cd ./deploy`
- Run the script to deploy Azure resources, compile & deploy application code as an Azure function
  - `$ ./deploy.sh`

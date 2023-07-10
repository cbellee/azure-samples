rgName='cosmos-mongodb-func-rg'
location='australiaeast'
subscriptionId=$(az account show --query id --output tsv)

# create custom RBAC role
sed "s/<subscriptionId>/$subscriptionId/g" ./cosmos_db_listkeys_role.template >> ./cosmos_db_listkeys_role.json

roleExists = $(az role definition list --name 'CosmosDB List Keys')
if [ "$roleExists" == null ]; then
    az role definition create --role-definition ./cosmos_db_listkeys_role.json
fi

cosmosDBCustomRoleDefinitionId=$(az role definition list --name 'CosmosDB List Keys' --query [].id --output tsv)

# create resource group
az group create -n $rgName --location $location  

# deploy infrastructure
az deployment group create \
    -n 'infra-deployment' \
    -g $rgName \
    --template-file ./deploy.bicep \
    --parameters cosmosDBCustomRoleDefinitionId=$cosmosDBCustomRoleDefinitionId

functionAppName=$(az deployment group show \
    --name 'infra-deployment' \
    -g $rgName --query properties.outputs.functionAppName.value -o tsv)

# publish & zip function app 
cd ../src/TodoApi
dotnet publish -p:PublishReadyToRun=true
cd ./bin/Debug/net6.0/linux-x64/publish
zip -r ./deploy.zip .

# deploy function app as zip package
az functionapp deployment source config-zip -g $rgName -n $functionAppName --src ./deploy.zip

curl https://$functionAppName.azurewebsites.net/api/todo -d '{"title":"get dog food","iscomplete":true}'

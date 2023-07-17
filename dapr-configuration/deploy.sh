rgName="aca-dapr-config-aue-rg"
location="australiaeast"
appName='dapr-config-app'

# create resource group
az group create --name $rgName --location $location

# deploy acr
acrName=$(az deployment group create \
    --resource-group $rgName \
    --template-file ./acr.bicep \
    --parameters location=$location \
    --query properties.outputs.acrName.value -o tsv)

# build and push image
imageName="$acrName.azurecr.io/$appName:v0.0.1"
az acr build -t $imageName -r $acrName .

# deploy infrastructure
az deployment group create \
    --resource-group $rgName \
    --template-file ./deploy.bicep \
    --parameters imageName=$imageName \
    --parameters location=$location \
    --parameters acrName=$acrName \
    --parameters appName=$appName

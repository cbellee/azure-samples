rgName='cosmos-mongodb-mid-rg'
location='australiaeast'
funcName='dexkpuajo7isu-fa'

az group create -n $rgName --location $location  
az deployment group create -n 'infra-deployment' -g $rgName --template-file ./deploy.bicep

cd ../src/Todo.Api/bin/Debug/net6.0/publish
zip -r ../../../../../../deploy/deploy.zip .
cd ../../../../../../

az functionapp deployment source config-zip -g $rgName -n $funcName --src ./deploy.zip
az webapp log deployment show -n dexkpuajo7isu-fa -g cosmos-mongodb-mid-rg

curl https://dexkpuajo7isu-fa.azurewebsites.net/api/todo -d '{"id":"1000","Title":"get milk","IsComplete":true}'
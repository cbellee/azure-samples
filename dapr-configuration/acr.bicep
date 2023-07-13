param location string

var prefix = uniqueString(resourceGroup().id)
var acrName = '${prefix}acr'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
  }
}

output acrName string = acr.name

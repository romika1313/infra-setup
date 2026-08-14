param name string
param location string
param tags object = {}

resource mapsAccount 'Microsoft.Maps/accounts@2023-06-01' = {
  name: name
  location: location
  tags: tags
  kind: 'Gen2'
  sku: { name: 'G2' }
  properties: {
    disableLocalAuth: false
  }
}

output id string = mapsAccount.id
output name string = mapsAccount.name

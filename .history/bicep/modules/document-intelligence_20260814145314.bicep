param name string
param location string
param tags object = {}
// F0 = free (500 pages/month); use S0 for production
param skuName string = 'F0'

resource docIntelligence 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'FormRecognizer'
  sku: { name: skuName }
  properties: {
    publicNetworkAccess: 'Enabled'
    customSubDomainName: name
  }
}

output id string = docIntelligence.id
output name string = docIntelligence.name
output endpoint string = docIntelligence.properties.endpoint

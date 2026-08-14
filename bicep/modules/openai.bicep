param name string
param location string
param tags object = {}
param skuName string = 'S0'
param deploymentName string = 'gpt-5-mini'
param modelName string = 'gpt-5-mini'
param modelVersion string = '2025-08-07'
// capacity unit = thousands of tokens per minute (TPM); 10 = 10K TPM
param capacity int = 10

resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: { name: skuName }
  properties: {
    publicNetworkAccess: 'Enabled'
    customSubDomainName: name
  }
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: openAi
  name: deploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
}

output id string = openAi.id
output name string = openAi.name
output endpoint string = openAi.properties.endpoint
output deploymentName string = modelDeployment.name

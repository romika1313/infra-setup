// Writes auto-derived secrets into Key Vault.
// Placeholder secrets for manually-managed values are NOT created here —
// create them in Key Vault after deploy (see workflow comments for the list).

param keyVaultName string

@secure()
param storageConnectionString string

@secure()
param databaseUrl string

@secure()
param docIntelligenceKey string

@secure()
param openAiApiKey string

@secure()
param mapsKey string

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource secretStorage 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'storage-connection-string'
  properties: { value: storageConnectionString }
}

resource secretDatabaseUrl 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'database-url'
  properties: { value: databaseUrl }
}

resource secretDocIntKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'document-intelligence-key'
  properties: { value: docIntelligenceKey }
}

resource secretOpenAiKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'azure-openai-api-key'
  properties: { value: openAiApiKey }
}

resource secretMapsKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'azure-maps-key'
  properties: { value: mapsKey }
}

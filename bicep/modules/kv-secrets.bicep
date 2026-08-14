// Writes auto-derived secrets into Key Vault.
// listKeys() is called on existing resource references — this is the correct
// Bicep pattern; calling listKeys() on module output IDs is not supported.
// Placeholder secrets for manually-managed values are NOT created here —
// see workflow comments for the list of secrets you must add manually.

param keyVaultName string
param storageAccountName string
param docIntelligenceName string
param openAiName string
param mapsName string

// SQL connection string components
param sqlServerFqdn string
param sqlDatabaseName string
param sqlAdminLogin string

@secure()
param sqlAdminPassword string

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource docInt 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: docIntelligenceName
}

resource openAiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAiName
}

resource mapsAccount 'Microsoft.Maps/accounts@2023-06-01' existing = {
  name: mapsName
}

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
var databaseUrl = 'sqlserver://${sqlServerFqdn}:1433;database=${sqlDatabaseName};user=${sqlAdminLogin};password=${sqlAdminPassword};encrypt=true;trustServerCertificate=false;loginTimeout=30'

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
  properties: { value: docInt.listKeys().key1 }
}

resource secretOpenAiKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'azure-openai-api-key'
  properties: { value: openAiAccount.listKeys().key1 }
}

resource secretMapsKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'azure-maps-key'
  properties: { value: mapsAccount.listKeys().primaryKey }
}

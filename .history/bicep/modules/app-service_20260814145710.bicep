param planName string
param siteName string
param location string
param tags object = {}
param planSkuName string = 'B1'
param planSkuTier string = 'Basic'

// Key Vault URI ends with a trailing slash: https://kv-name.vault.azure.net/
param keyVaultUri string

param appInsightsConnectionString string
param azureAdClientId string = ''
param azureTenantId string
param docIntelligenceEndpoint string
param openAiEndpoint string
param openAiDeploymentName string = 'gpt-4o-mini'


resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: planSkuName
    tier: planSkuTier
  }
  properties: {
    reserved: true // required for Linux plans
  }
}

resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: siteName
  location: location
  tags: tags
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|22-lts'
      appCommandLine: 'npm run start'
      alwaysOn: true
      healthCheckPath: '/api/health'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [
        // ---- Runtime config (not secrets) ----
        { name: 'NODE_ENV',                          value: 'production' }
        { name: 'SCM_DO_BUILD_DURING_DEPLOYMENT',    value: 'false' }
        { name: 'AZURE_STORAGE_CONTAINER',           value: 'receipts' }
        { name: 'ALLOW_MOCK_AUTH',                   value: 'false' }
        { name: 'DIRECTORY_MOCK',                    value: 'false' }
        { name: 'OCR_PROVIDER',                      value: 'document-intelligence' }
        { name: 'OCR_MOCK',                          value: 'false' }
        { name: 'MAPS_MOCK',                         value: 'false' }
        { name: 'LOG_LEVEL',                         value: 'info' }
        { name: 'AZURE_AD_CLIENT_ID',                value: azureAdClientId }
        { name: 'AZURE_AD_TENANT_ID',                value: azureTenantId }
        { name: 'DOCUMENT_INTELLIGENCE_ENDPOINT',    value: docIntelligenceEndpoint }
        { name: 'AZURE_OPENAI_ENDPOINT',             value: openAiEndpoint }
        { name: 'AZURE_OPENAI_DEPLOYMENT',           value: openAiDeploymentName }
        { name: 'AZURE_OPENAI_API_VERSION',          value: '2024-10-21' }
        { name: 'AZURE_MAPS_BASE_URL',               value: 'https://atlas.microsoft.com' }
        { name: 'NEXTAUTH_URL',                      value: 'https://${siteName}.azurewebsites.net' }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsightsConnectionString }

        // ---- Secrets via Key Vault references ----
        // App Service resolves these at runtime; the app refuses to start if required ones are missing.
        // Format: @Microsoft.KeyVault(SecretUri=<vaultUri>secrets/<name>/)  — trailing slash = latest version
        { name: 'DATABASE_URL',                      value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/database-url/)' }
        { name: 'NEXTAUTH_SECRET',                   value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/nextauth-secret/)' }
        { name: 'AZURE_AD_CLIENT_SECRET',            value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/azure-ad-client-secret/)' }
        { name: 'AZURE_STORAGE_CONNECTION_STRING',   value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/storage-connection-string/)' }
        { name: 'DOCUMENT_INTELLIGENCE_KEY',         value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/document-intelligence-key/)' }
        { name: 'AZURE_OPENAI_API_KEY',              value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/azure-openai-api-key/)' }
        { name: 'AZURE_MAPS_KEY',                    value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/azure-maps-key/)' }
        { name: 'INGEST_SHARED_SECRET',              value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/ingest-shared-secret/)' }
        { name: 'DIGEST_SHARED_SECRET',              value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/digest-shared-secret/)' }
      ]
    }
  }
}

output id string = appService.id
output name string = appService.name
output principalId string = appService.identity.principalId
output defaultHostname string = appService.properties.defaultHostName

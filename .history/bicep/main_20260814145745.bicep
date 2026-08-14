targetScope = 'subscription'

// ── Identity ────────────────────────────────────────────────────────────────
@description('Short environment label: dev | test | prod')
param environmentName string

param location string = 'eastus2'
param resourceGroupName string

// ── SQL credentials ──────────────────────────────────────────────────────────
param sqlAdminLogin string = 'sqladmin'

@secure()
param sqlAdminPassword string

// ── Entra ID (set after app registration is created) ────────────────────────
param azureAdClientId string = ''

// ── Azure OpenAI model ───────────────────────────────────────────────────────
param openAiDeploymentName string = 'gpt-4o-mini'
param openAiModelVersion string = '2024-07-18'
param openAiCapacity int = 10

// ── Per-environment SKU overrides ────────────────────────────────────────────
param appServicePlanSku string = 'B1'
param appServicePlanTier string = 'Basic'
param sqlSkuName string = 'Basic'
param sqlSkuTier string = 'Basic'
param sqlSkuCapacity int = 5
param sqlBackupRedundancy string = 'Local'
param storageSkuName string = 'Standard_LRS'
param docIntSkuName string = 'F0'

// ── Derived names (consistent across all environments) ───────────────────────
var abbr = 'eus2'
var appInsightsName          = 'appi-expense-${environmentName}-${abbr}'
var keyVaultName             = 'kv-expense-${environmentName}-${abbr}'
var storageAccountName       = 'stexpense${environmentName}${abbr}'
var sqlServerName            = 'sql-expense-${environmentName}-${abbr}'
var sqlDatabaseName          = 'expense-hub-${environmentName}'
var appServicePlanName       = 'asp-expense-${environmentName}-${abbr}'
var appServiceName           = 'app-expense-${environmentName}'
var docIntName               = 'docint-expense-${environmentName}-${abbr}'
var openAiName               = 'oai-expense-${environmentName}-${abbr}'
var mapsName                 = 'maps-expense-${environmentName}-${abbr}'

var tags = {
  environment: environmentName
  application: 'expense-hub'
  managedBy: 'bicep'
}

// ── Resource Group ───────────────────────────────────────────────────────────
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ── App Insights + Log Analytics ─────────────────────────────────────────────
module appInsights './modules/app-insights.bicep' = {
  name: 'appInsights'
  scope: rg
  params: {
    name: appInsightsName
    location: location
    tags: tags
  }
}

// ── Key Vault ────────────────────────────────────────────────────────────────
module keyVault './modules/key-vault.bicep' = {
  name: 'keyVault'
  scope: rg
  params: {
    name: keyVaultName
    location: location
    tags: tags
  }
}

// ── Storage ──────────────────────────────────────────────────────────────────
module storage './modules/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: storageAccountName
    location: location
    tags: tags
    skuName: storageSkuName
  }
}

// ── Azure SQL ────────────────────────────────────────────────────────────────
module sql './modules/sql.bicep' = {
  name: 'sql'
  scope: rg
  params: {
    serverName: sqlServerName
    databaseName: sqlDatabaseName
    location: location
    tags: tags
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    skuName: sqlSkuName
    skuTier: sqlSkuTier
    skuCapacity: sqlSkuCapacity
    backupRedundancy: sqlBackupRedundancy
  }
}

// ── Document Intelligence ────────────────────────────────────────────────────
module docIntelligence './modules/document-intelligence.bicep' = {
  name: 'documentIntelligence'
  scope: rg
  params: {
    name: docIntName
    location: location
    tags: tags
    skuName: docIntSkuName
  }
}

// ── Azure OpenAI ─────────────────────────────────────────────────────────────
module openAi './modules/openai.bicep' = {
  name: 'openAi'
  scope: rg
  params: {
    name: openAiName
    location: location
    tags: tags
    deploymentName: openAiDeploymentName
    modelName: openAiDeploymentName
    modelVersion: openAiModelVersion
    capacity: openAiCapacity
  }
}

// ── Azure Maps ───────────────────────────────────────────────────────────────
module maps './modules/maps.bicep' = {
  name: 'maps'
  scope: rg
  params: {
    name: mapsName
    location: location
    tags: tags
  }
}

// ── App Service (depends on Key Vault URI and App Insights) ──────────────────
module appService './modules/app-service.bicep' = {
  name: 'appService'
  scope: rg
  params: {
    planName: appServicePlanName
    siteName: appServiceName
    location: location
    tags: tags
    planSkuName: appServicePlanSku
    planSkuTier: appServicePlanTier
    keyVaultUri: keyVault.outputs.uri
    appInsightsConnectionString: appInsights.outputs.connectionString
    azureAdClientId: azureAdClientId
    azureTenantId: subscription().tenantId
    docIntelligenceEndpoint: docIntelligence.outputs.endpoint
    openAiEndpoint: openAi.outputs.endpoint
    openAiDeploymentName: openAiDeploymentName
  }
}

// ── RBAC: grant App Service managed identity access to KV and Storage ────────
// Runs after appService (needs principalId) and keyVault/storage (needs names)
module rbac './modules/rbac.bicep' = {
  name: 'rbac'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    storageAccountName: storage.outputs.name
    appServicePrincipalId: appService.outputs.principalId
  }
}

// ── Key Vault secrets (auto-derived from the resources created above) ─────────
// kv-secrets.bicep uses 'existing' references + listKeys() — the correct Bicep
// pattern. listKeys() on module output IDs is not supported (runtime values).
// Runs after rbac so the deployment identity can write secrets.
module kvSecrets './modules/kv-secrets.bicep' = {
  name: 'kvSecrets'
  scope: rg
  dependsOn: [rbac]
  params: {
    keyVaultName: keyVault.outputs.name
    storageAccountName: storage.outputs.name
    docIntelligenceName: docIntelligence.outputs.name
    openAiName: openAi.outputs.name
    mapsName: maps.outputs.name
    sqlServerFqdn: sql.outputs.serverFqdn
    sqlDatabaseName: sqlDatabaseName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────
output appServiceUrl string = 'https://${appService.outputs.defaultHostname}'
output appServiceName string = appService.outputs.name
output keyVaultName string = keyVault.outputs.name
output sqlServerFqdn string = sql.outputs.serverFqdn
output storageAccountName string = storage.outputs.name

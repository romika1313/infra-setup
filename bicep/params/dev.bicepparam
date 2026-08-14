using '../main.bicep'

// ── DEV environment ───────────────────────────────────────────────────────────
// sqlAdminPassword is NOT here — pass it via CLI:
//   --parameters sqlAdminPassword="<value>"
// azureAdClientId: set this after creating the Entra app registration

param environmentName = 'dev'
param location = 'eastus2'
// App Service must be in Central US — subscription has no compute quota in East US 2
param appServiceLocation = 'centralus'

param sqlAdminLogin = 'sqladmin'
// Empty here — CI injects the real value from the "dev" environment secret SQL_ADMIN_PASSWORD
param sqlAdminPassword = ''
param azureAdClientId = ''  // TODO: set after Entra app registration

// App Service: Basic B1 (cheapest, no slots — fine for dev)
param appServicePlanSku = 'B1'
param appServicePlanTier = 'Basic'

// SQL: Basic 5 DTU (matches existing POC)
param sqlSkuName = 'Basic'
param sqlSkuTier = 'Basic'
param sqlSkuCapacity = 5
param sqlBackupRedundancy = 'Local'

// Storage: locally-redundant (fine for dev)
param storageSkuName = 'Standard_LRS'

// S0 (not F0) — subscription already has one free FormRecognizer account (the POC); only one allowed.
param docIntSkuName = 'S0'

// OpenAI
param openAiDeploymentName = 'gpt-5-mini'
param openAiModelVersion = '2025-08-07'
param openAiCapacity = 10

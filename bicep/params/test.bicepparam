using '../main.bicep'

// ── TEST environment ──────────────────────────────────────────────────────────
// Mirror of DEV with slightly more capacity; still free-tier AI services.
// sqlAdminPassword is NOT here — pass it via CLI.

param environmentName = 'test'
param location = 'eastus2'

param sqlAdminLogin = 'sqladmin'
// Empty here — CI injects the real value from the "test" environment secret SQL_ADMIN_PASSWORD
param sqlAdminPassword = ''
param azureAdClientId = ''  // TODO: set after Entra app registration

param appServicePlanSku = 'B2'
param appServicePlanTier = 'Basic'

param sqlSkuName = 'Basic'
param sqlSkuTier = 'Basic'
param sqlSkuCapacity = 5
param sqlBackupRedundancy = 'Local'

param storageSkuName = 'Standard_LRS'
param docIntSkuName = 'S0'

param openAiDeploymentName = 'gpt-4o-mini'
param openAiModelVersion = '2024-07-18'
param openAiCapacity = 10

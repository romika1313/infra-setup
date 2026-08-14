using '../main.bicep'

// ── DEV environment ───────────────────────────────────────────────────────────
// sqlAdminPassword is NOT here — pass it via CLI:
//   --parameters sqlAdminPassword="<value>"
// azureAdClientId: set this after creating the Entra app registration

param environmentName = 'dev'
param location = 'eastus2'
param resourceGroupName = 'rgrp-expense-dev-eus2'

param sqlAdminLogin = 'sqladmin'
// Empty here — CI injects the real value with: --parameters sqlAdminPassword="${{ secrets.SQL_ADMIN_PASSWORD_DEV }}"
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

// Document Intelligence: free tier (500 pages/month)
param docIntSkuName = 'F0'

// OpenAI
param openAiDeploymentName = 'gpt-4o-mini'
param openAiModelVersion = '2024-07-18'
param openAiCapacity = 10

using '../main.bicep'

// ── PROD environment ──────────────────────────────────────────────────────────
// Standard tier App Service (required for deployment slots + scale-out).
// Paid-tier Document Intelligence (S0 = no page cap).
// Geo-redundant storage (GRS) for receipt durability.
// sqlAdminPassword is NOT here — pass it via CLI.

param environmentName = 'prod'
param location = 'eastus2'
param resourceGroupName = 'rgrp-expense-prod-eus2'

param sqlAdminLogin = 'sqladmin'
// Empty here — CI injects the real value with: --parameters sqlAdminPassword="${{ secrets.SQL_ADMIN_PASSWORD_PROD }}"
param sqlAdminPassword = ''
param azureAdClientId = ''  // TODO: set after Entra app registration

// Standard S2: supports deployment slots (needed for zero-downtime deploy)
param appServicePlanSku = 'S2'
param appServicePlanTier = 'Standard'

// S1: 20 DTU, 250 GB max — resize based on actual usage after go-live
param sqlSkuName = 'S1'
param sqlSkuTier = 'Standard'
param sqlSkuCapacity = 20
param sqlBackupRedundancy = 'Geo'

// GRS: geo-redundant receipt storage (PROD only)
param storageSkuName = 'Standard_GRS'

// S0: paid tier, no page cap
param docIntSkuName = 'S0'

param openAiDeploymentName = 'gpt-4o-mini'
param openAiModelVersion = '2024-07-18'
param openAiCapacity = 30

// Grants the App Service managed identity read access to Key Vault and Storage.
// Also grants the deploying service principal write access to Key Vault secrets
// so Bicep can populate secrets during deployment (Owner alone is not enough
// for Key Vault data-plane operations when RBAC authorization is enabled).

param keyVaultName string
param storageAccountName string
param appServicePrincipalId string
// Object ID of the GitHub Actions service principal (not the client ID)
param deployingPrincipalId string = ''

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// Key Vault Secrets User: read secrets (cannot manage them)
var kvSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'
// Key Vault Secrets Officer: read + write secrets (needed by the deploying principal)
var kvSecretsOfficerRoleId = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
// Storage Blob Data Contributor: read/write blobs (receipts, map images)
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, appServicePrincipalId, kvSecretsUserRoleId)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsUserRoleId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, appServicePrincipalId, storageBlobDataContributorRoleId)
  scope: storage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Only created when deployingPrincipalId is supplied (skipped on local runs)
resource kvDeployerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(deployingPrincipalId)) {
  name: guid(kv.id, deployingPrincipalId, kvSecretsOfficerRoleId)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsOfficerRoleId)
    principalId: deployingPrincipalId
    principalType: 'ServicePrincipal'
  }
}

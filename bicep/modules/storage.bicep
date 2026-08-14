param name string
param location string
param tags object = {}
param skuName string = 'Standard_LRS'
param containerName string = 'receipts'
param blobSoftDeleteDays int = 7

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: { name: skuName }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: { enabled: true, days: blobSoftDeleteDays }
    containerDeleteRetentionPolicy: { enabled: true, days: blobSoftDeleteDays }
  }
}

resource receiptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: containerName
  properties: { publicAccess: 'None' }
}

output id string = storageAccount.id
output name string = storageAccount.name

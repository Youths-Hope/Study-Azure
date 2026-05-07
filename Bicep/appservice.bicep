param location string
param appName string
param planName string
param dbHost string
param dbUser string
param dbName string
param storageAccountName string
param containerName string
param keyVaultName string
param operatorObjectId string

// =======================
// App Service Plan（Free F1）
// =======================
resource plan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: planName
  location: location
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  kind: 'linux'
  properties: {
    reserved: true // Linux必須
  }
}

// =======================
// App Service
// =======================
resource app 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    serverFarmId: plan.id

    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'

      appSettings: [
        {
          name: 'DB_HOST'
          value: dbHost
        }
        {
          name: 'DB_USER'
          value: dbUser
        }
        {
          name: 'DB_NAME'
          value: dbName
        }
        {
          name: 'STORAGE_ACCOUNT'
          value: storageAccountName
        }
        {
          name: 'CONTAINER_NAME'
          value: containerName
        }
      ]
    }
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource blobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, app.id, 'blob-data-contributor')
  scope: storage
  properties: {
    principalId: app.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )
  }
}

resource keyVaultUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, app.id, 'kv-secrets-user')
  scope: keyVault
  properties: {
    principalId: app.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )
  }
}

resource keyVaultOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, operatorObjectId, 'kv-secrets-officer')
  scope: keyVault
  properties: {
    principalId: operatorObjectId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
    )
  }
}
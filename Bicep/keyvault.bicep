param location string
param keyVaultName string

@secure()
param dbPassword string = ''

@allowed([
  'create'
  'recover'
])
param kvMode string = 'create'

// =======================
// Key Vault（create or recover）
// =======================
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location

  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }

    enableRbacAuthorization: true

    // 🔥 ここが切り替えポイント
    createMode: kvMode == 'recover' ? 'recover' : null
  }
}

// =======================
// Secret（create時のみ）
// =======================
resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (kvMode == 'create') {
  name: '${kv.name}/DBPASSWORD'
  properties: {
    value: dbPassword
  }
}

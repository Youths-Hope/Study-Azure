targetScope = 'subscription'

@description('作成するリソースグループ名')
param rgName string = 'study-rg'

@description('リソースグループのリージョン')
param rgLocation string = 'japaneast'

@description('MySQL のリージョン')
param mysqlLocation string = 'koreacentral'

@description('App Service のリージョン')
param appLocation string = 'malaysiawest'

@description('MySQL サーバー名')
param serverName string = 'study-mysql-youth001'

@description('MySQL DB名')
param dbName string = 'study_db'

@description('MySQL 管理者ユーザー')
param adminUser string = 'adminuser'

@secure()
@description('MySQL 管理者パスワード')
param adminPassword string

@description('Storage Account 名')
param storageName string = 'studystorageyouth001'

@description('Blob Container 名')
param containerName string = 'images'

@description('Key Vault 名')
param keyVaultName string = 'study-kv-youth001'

@description('App Service 名')
param appName string = 'study-app-001'

@description('Key Vault 作成/復元指定')
@allowed([
  'create'
  'recover'
])
param kvMode string = 'recover'

@description('App Service Plan 名')
param planName string = 'study-app-plan'

@description('ObjectID')
param operatorObjectId string

// =======================
// Resource Group
// =======================
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: rgLocation
}

// =======================
// MySQL
// =======================
module mysql './mysql.bicep' = {
  name: 'mysqlDeploy'
  scope: rg
  params: {
    location: mysqlLocation
    serverName: serverName
    dbName: dbName
    adminUser: adminUser
    adminPassword: adminPassword
  }
}

// =======================
// Storage
// =======================
module storage './storage.bicep' = {
  name: 'storageDeploy'
  scope: rg
  params: {
    location: rgLocation
    storageName: storageName
    containerName: containerName
  }
}

// =======================
// Key Vault
// =======================
//      (kvModeによる作成か復元を指定)
module keyvault './keyvault.bicep' = {
  name: 'keyVaultDeploy'
  scope: rg
  params: {
    location: rgLocation
    keyVaultName: keyVaultName
    dbPassword: adminPassword
    kvMode: kvMode
  }
}

// =======================
// App Service
// =======================
module app './appservice.bicep' = {
  name: 'appServiceDeploy'
  scope: rg
  dependsOn: [
    mysql
    storage
    keyvault
  ]
  params: {
    location: appLocation
    appName: appName
    planName: planName
    dbHost: '${serverName}.mysql.database.azure.com'
    dbUser: adminUser
    dbName: dbName
    storageAccountName: storageName
    containerName: containerName
    keyVaultName: keyVaultName
    operatorObjectId: operatorObjectId
  }
}
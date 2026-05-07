//param location string = resourceGroup().location
param location string = 'koreacentral'

param serverName string = 'study-mysql-youth001'
param dbName string = 'study_db'
param adminUser string = 'adminuser'
@secure()
param adminPassword string

// =======================
// MySQL Flexible Server
// =======================
resource mysql 'Microsoft.DBforMySQL/flexibleServers@2022-01-01' = {
  name: serverName
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: adminUser
    administratorLoginPassword: adminPassword
    version: '8.0.21'
    storage: {
      storageSizeGB: 20
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
}

resource firewall 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2022-01-01' = {
  name: 'AllowAzureServices'
  parent: mysql
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// =======================
// Database
// =======================
resource database 'Microsoft.DBforMySQL/flexibleServers/databases@2022-01-01' = {
  name: dbName
  parent: mysql
}
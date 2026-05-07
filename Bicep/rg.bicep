targetScope = 'subscription'

param rgName string = 'study-rg'
param location string = 'japaneast'

// リソースグループ作成
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}
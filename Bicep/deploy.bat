@echo off

echo =========================
echo Azure 起動
echo =========================
call az deployment sub create ^
   --location japaneast ^
   --template-file main.bicep ^
   --parameters ^
     rgName=study-rg ^
     rgLocation=japaneast ^
     mysqlLocation=koreacentral ^
     appLocation=malaysiawest ^
     serverName=study-mysql-youth001 ^
     dbName=study_db ^
     adminUser=adminuser ^
     adminPassword=Study-db ^
     storageName=studystorageyouth001 ^
     containerName=images ^
     keyVaultName=study-kv-youth001 ^
     appName=study-app-001 ^
     planName=study-app-plan ^
     operatorObjectId=c859a37d-4699-4a84-b9af-c934b8c4954f

echo =========================
echo ZIP作成
echo =========================

rem if exist app.zip del app.zip
rem 
rem powershell -Command "Compress-Archive -Path * -DestinationPath app.zip -Force"

echo =========================
echo Azure デプロイ開始
echo =========================

call az webapp deploy ^
  --resource-group study-rg ^
  --name study-app-001 ^
  --src-path ..\SSH-Key\app_full.zip ^
  --type zip

echo =========================
echo デプロイ完了
echo =========================

pause

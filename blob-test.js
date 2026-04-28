const { BlobServiceClient } = require('@azure/storage-blob');
const fs = require('fs');

const connectionString = '(★接続文字列を設定)';
const containerName = 'images';
const localFilePath = './sample.txt';
const blobName = 'sample.txt';

async function main() {
  fs.writeFileSync(localFilePath, 'Hello Azure Blob!');

  const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
  const containerClient = blobServiceClient.getContainerClient(containerName);
  const blockBlobClient = containerClient.getBlockBlobClient(blobName);

  await blockBlobClient.uploadFile(localFilePath);

  console.log('アップロード完了');
  console.log(`URL: ${blockBlobClient.url}`);
}

main().catch(console.error);

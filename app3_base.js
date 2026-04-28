const express = require('express');
const multer = require('multer');
const mysql = require('mysql2');
const { BlobServiceClient } = require('@azure/storage-blob');

const app = express();
app.use(express.urlencoded({ extended: true }));

// ===== DB接続 =====
const connection = mysql.createConnection({
    host: 'study-mysql-youth001.mysql.database.azure.com',
    user: 'adminuser',
    password: 'Study-db',
    database: 'study_db',
    ssl: { rejectUnauthorized: false }
});

// ===== Blob設定 =====
const account = process.env.STORAGE_ACCOUNT;
const containerName = process.env.CONTAINER_NAME;

const credential = new DefaultAzureCredential();

//const blobServiceClient = BlobServiceClient.fromConnectionString(connStr);
const blobServiceClient = new BlobServiceClient(
  `https://${account}.blob.core.windows.net`,
  credential
);

// ===== multer =====
const upload = multer({ dest: 'uploads/' });

// ===== 画面 =====
app.get('/', (req, res) => {
  res.send(`
    <h1>画像アップロード</h1>
    <form action="/upload" method="post" enctype="multipart/form-data">
      名前: <input type="text" name="name"><br>
      画像: <input type="file" name="image"><br>
      <button type="submit">送信</button>
    </form>
  `);
});

// ===== アップロード処理 =====
app.post('/upload', upload.single('image'), async (req, res) => {
  try {
    const file = req.file;
    const name = req.body.name;

    const containerClient = blobServiceClient.getContainerClient(containerName);
    const blobName = file.originalname;

    const blockBlobClient = containerClient.getBlockBlobClient(blobName);

    await blockBlobClient.uploadFile(file.path);

    const imageUrl = blockBlobClient.url;

    // DB保存
    connection.query(
        'INSERT INTO users (name, image_url) VALUES (?, ?)',
        [name, imageUrl]
    );

    res.send(`保存成功<br><a href="${imageUrl}">画像を見る</a>`);
  } catch (err) {
    console.error(err);
    res.send('エラー発生');
  }
});

// ===== 起動 =====
const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log('Server running');
});

app.get('/list', (req, res) => {
  connection.query('SELECT * FROM users', (err, results) => {
    if (err) {
      console.error(err);
      return res.send('DBエラー');
    }

    let html = '<h1>画像一覧</h1>';

    results.forEach(row => {
      html += `
        <div>
          <p>${row.name}</p>
          <img src="${row.image_url}" width="200">
        </div>
      `;
    });

    res.send(html);
  });
});

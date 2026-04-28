const express = require('express');
const multer = require('multer');
const mysql = require('mysql2');
const path = require('path');

const app = express();
app.use(express.urlencoded({ extended: true }));

// ===== Blob設定 =====
const account = process.env.STORAGE_ACCOUNT;
const containerName = process.env.CONTAINER_NAME;

const { DefaultAzureCredential } = require('@azure/identity');
const { BlobServiceClient } = require('@azure/storage-blob');

const credential = new DefaultAzureCredential();

const blobServiceClient = new BlobServiceClient(
  `https://${account}.blob.core.windows.net`,
  credential
);

const containerClient = blobServiceClient.getContainerClient(containerName);

// ===== DB接続 =====
const { SecretClient } = require("@azure/keyvault-secrets");

// ここから(for async)
let connection;

async function startApp() {
  const client = new SecretClient(
    "https://study-kv-youth001.vault.azure.net/",
    credential
  );

  const secret = await client.getSecret("DBPASSWORD");
  console.log('Key Vault 取得成功');

  connection = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: secret.value,
    database: process.env.DB_NAME,
    ssl: { rejectUnauthorized: false }
  });

  connection.connect((err) => {
    if (err) {
      console.error('DB接続エラー:', err);
      return;
    }

    console.log('DB接続成功');

    // ===== テーブル作成 =====
    const createTableSql = `
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100),
        email VARCHAR(255) NULL,
        image_url TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `;

    connection.query(createTableSql, (err) => {
      if (err) {
        console.error('テーブル作成エラー:', err);
        return;
      }

      console.log('users テーブル確認OK');

      const port = process.env.PORT || 3000;
      app.listen(port, () => {
        console.log(`Server running on port ${port}`);
      });
    });
  });
}

startApp().catch((err) => {
  console.error('起動エラー:', err);
});
// ここまで(for async)

// ===== multer =====
const upload = multer({ dest: 'uploads/' });

// ===== 画面 =====
app.get('/', (req, res) => {
  res.send(`
    <a href="/list">一覧を見る</a>
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

    if (!file) {
        return res.send('画像ファイルが選択されていません');
    }

    const containerClient = blobServiceClient.getContainerClient(containerName);
    //const blobName = file.originalname;
    const ext = path.extname(file.originalname);
    const blobName = `${Date.now()}${ext}`;

    const blockBlobClient = containerClient.getBlockBlobClient(blobName);
    await blockBlobClient.uploadFile(file.path);

    const imageUrl = blockBlobClient.url;

    // DB保存
    connection.query(
      'INSERT INTO users (name, image_url) VALUES (?, ?)',
      [name, imageUrl],
      (err) => {
        if (err) {
          console.error('DB保存エラー:', err);
          return res.send('DB保存エラー');
        }

        res.send(`保存成功<br><a href="${imageUrl}">画像を見る</a>`);
      }
    );
  } catch (err) {
    console.error(err);
    res.send('エラー発生');
  }
});

app.post('/delete/:id', (req, res) => {
  const id = req.params.id;

  connection.query(
    'SELECT image_url FROM users WHERE id = ?',
    [id],
    async (err, results) => {
      if (err) {
        console.error('取得エラー:', err);
        return res.send('取得エラー');
      }

      if (results.length === 0) {
        return res.send('対象データが見つかりません');
      }

      const imageUrl = results[0].image_url;

      try {
        if (imageUrl) {
          const blobName = imageUrl.split('/').pop();
          const blockBlobClient = containerClient.getBlockBlobClient(blobName);
          await blockBlobClient.deleteIfExists();
        }

        connection.query(
          'DELETE FROM users WHERE id = ?',
          [id],
          (deleteErr) => {
            if (deleteErr) {
              console.error('DB削除エラー:', deleteErr);
              return res.send('DB削除エラー');
            }

            res.redirect('/list');
          }
        );
      } catch (blobErr) {
        console.error('Blob削除エラー:', blobErr);
        res.send('Blob削除エラー');
      }
    }
  );
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
        <div style="margin-bottom:20px;">
          <p>${row.name}</p>
          ${row.image_url ? `<img src="${row.image_url}" width="200"><br>` : ''}
          <form action="/delete/${row.id}" method="post" style="margin-top:10px;">
            <button type="submit">削除</button>
          </form>
        </div>
        <hr>
      `;
    });

    res.send(html);
  });
});

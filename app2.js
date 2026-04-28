const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: 'study-mysql-youth001.mysql.database.azure.com',
  user: 'adminuser',
  password: 'Study-db',
  database: 'study_db',
  ssl: {
    rejectUnauthorized: false
  }
});

connection.connect();

connection.query('SELECT * FROM users', (err, results) => {
  console.log(results);
});


const mysql = require('mysql2/promise');
const config = require('config');

const DB_HOST = process.env.DB_HOST || 'mysql-service';
const DB_PORT = process.env.DB_PORT || '3306';
const DB_NAME = process.env.DB_NAME || 'my_db';
const DB_USERNAME = process.env.DB_USER || 'root';
const DB_USERNAME_PASSWORD = process.env.DB_PASSWORD || 'rootpassword';

const connectionOptions = {
    host: DB_HOST,
    port: DB_PORT,
    database: DB_NAME,
    user: DB_USERNAME,
    password: DB_USERNAME_PASSWORD,
};

const pool = mysql.createPool(connectionOptions);

const connectToMySQL = async () => {
    try {
        await pool.getConnection();

        console.log('MySQL database connected!');
    } catch (err) {
        console.log('MySQL database connection error!');

        process.exit(1);
    }
};

connectToMySQL().then();

module.exports = pool;

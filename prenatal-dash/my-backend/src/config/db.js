const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'maternalink',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
  process.exit(-1);
});

const query = async (text, params) => {
  const start = Date.now();
  const result = await pool.query(text, params);
  const duration = Date.now() - start;
  if (process.env.NODE_ENV === 'development') {
    console.log('📊 Query:', { text: text.substring(0, 80), duration: `${duration}ms`, rows: result.rowCount });
  }
  return result;
};

const getClient = async () => {
  const client = await pool.connect();
  return client;
};

const testConnection = async () => {
  try {
    const result = await query('SELECT NOW() as current_time');
    console.log(`✅ PostgreSQL connected at ${result.rows[0].current_time}`);
    return true;
  } catch (err) {
    console.error('❌ PostgreSQL connection failed:', err.message);
    return false;
  }
};

module.exports = { pool, query, getClient, testConnection };

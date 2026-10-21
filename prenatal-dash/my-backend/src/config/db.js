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

const initDbSchema = async () => {
  try {
    await query(`
      ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS is_flagged BOOLEAN DEFAULT false;
      ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS report_count INTEGER DEFAULT 0;
      ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS report_reason TEXT;

      CREATE TABLE IF NOT EXISTS community_rules (
        id VARCHAR(50) PRIMARY KEY DEFAULT 'default',
        content TEXT NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS direct_messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        message_text TEXT NOT NULL,
        is_read BOOLEAN DEFAULT false,
        is_edited BOOLEAN DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      ALTER TABLE direct_messages ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT false;
      CREATE INDEX IF NOT EXISTS idx_direct_messages_sender ON direct_messages(sender_id);
      CREATE INDEX IF NOT EXISTS idx_direct_messages_receiver ON direct_messages(receiver_id);
      CREATE INDEX IF NOT EXISTS idx_direct_messages_created_at ON direct_messages(created_at);
    `);
    console.log('✅ Community & Direct Messaging database schema verified');
  } catch (err) {
    console.warn('⚠️ Note during schema init:', err.message);
  }
};

const testConnection = async () => {
  try {
    const result = await query('SELECT NOW() as current_time');
    console.log(`✅ PostgreSQL connected at ${result.rows[0].current_time}`);
    await initDbSchema();
    return true;
  } catch (err) {
    console.error('❌ PostgreSQL connection failed:', err.message);
    return false;
  }
};

module.exports = { pool, query, getClient, testConnection, initDbSchema };

require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const knexConfig = require('../../knexfile');
const knex = require('knex')(knexConfig[process.env.NODE_ENV || 'development']);

async function runCmsSeed() {
  try {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🌱 Starting CMS Seed for PostgreSQL...');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    const { seed } = require('../seeds/02_cms_content');
    await seed(knex);

    console.log('\n✅ CMS Seeding successfully finished!');
  } catch (err) {
    console.error('❌ CMS Seed error:', err);
    process.exit(1);
  } finally {
    await knex.destroy();
    process.exit(0);
  }
}

runCmsSeed();

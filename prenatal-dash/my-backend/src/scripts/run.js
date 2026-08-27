require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const knexConfig = require('../../knexfile');
const knex = require('knex')(knexConfig[process.env.NODE_ENV || 'development']);

async function run() {
  try {
    console.log('🌱 Running MaternaLink seed...');

    // 1. Seed health providers
    const { seed: hpSeed } = require('../seeds/01_health_providers');
    await hpSeed(knex);

    console.log('✅ Seeds completed!');
  } catch (err) {
    console.error('❌ Seed error:', err);
    process.exit(1);
  } finally {
    await knex.destroy();
    process.exit(0);
  }
}

run();

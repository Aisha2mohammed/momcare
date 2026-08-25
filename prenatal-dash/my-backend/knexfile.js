require('dotenv').config();

/**
 * Knex configuration for MaternaLink PostgreSQL database
 * Supports development, production, and test environments
 */
module.exports = {
  development: {
    client: 'pg',
    connection: {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      database: process.env.DB_NAME || 'maternalink',
    },
    pool: {
      min: 2,
      max: 10,
    },
    migrations: {
      directory: './src/migrations',
      extension: 'js',
    },
    seeds: {
      directory: './src/seeds',
    },
  },

  production: {
    client: 'pg',
    connection: {
      host: process.env.DB_HOST,
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      ssl: { rejectUnauthorized: false },
    },
    pool: {
      min: 2,
      max: 20,
    },
    migrations: {
      directory: './src/migrations',
      extension: 'js',
    },
    seeds: {
      directory: './src/seeds',
    },
  },

  test: {
    client: 'pg',
    connection: {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      database: 'maternalink_test',
    },
    pool: { min: 1, max: 5 },
    migrations: {
      directory: './src/migrations',
      extension: 'js',
    },
    seeds: {
      directory: './src/seeds',
    },
  },
};


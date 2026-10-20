/**
 * Migration: Add multilingual and targeting columns to notifications
 */
exports.up = async function(knex) {
  const hasTitleSo = await knex.schema.hasColumn('notifications', 'title_so');
  if (!hasTitleSo) {
    await knex.schema.alterTable('notifications', (table) => {
      table.text('title_so').nullable();
    });
  }

  const hasBodySo = await knex.schema.hasColumn('notifications', 'body_so');
  if (!hasBodySo) {
    await knex.schema.alterTable('notifications', (table) => {
      table.text('body_so').nullable();
    });
  }

  const hasType = await knex.schema.hasColumn('notifications', 'type');
  if (!hasType) {
    await knex.schema.alterTable('notifications', (table) => {
      table.string('type', 50).defaultTo('reminder');
    });
  }

  const hasTrimester = await knex.schema.hasColumn('notifications', 'trimester');
  if (!hasTrimester) {
    await knex.schema.alterTable('notifications', (table) => {
      table.integer('trimester').nullable();
    });
  }

  const hasWeek = await knex.schema.hasColumn('notifications', 'week');
  if (!hasWeek) {
    await knex.schema.alterTable('notifications', (table) => {
      table.integer('week').nullable();
    });
  }

  const hasMonth = await knex.schema.hasColumn('notifications', 'month');
  if (!hasMonth) {
    await knex.schema.alterTable('notifications', (table) => {
      table.integer('month').nullable();
    });
  }
};

exports.down = async function(knex) {
  await knex.schema.alterTable('notifications', (table) => {
    table.dropColumn('month');
    table.dropColumn('week');
    table.dropColumn('trimester');
    table.dropColumn('type');
    table.dropColumn('body_so');
    table.dropColumn('title_so');
  });
};

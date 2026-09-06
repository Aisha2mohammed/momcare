exports.up = async function (knex) {
  await knex.schema.alterTable('notifications', (table) => {
    table.integer('sent_count').defaultTo(0);
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('notifications', (table) => {
    table.dropColumn('sent_count');
  });
};
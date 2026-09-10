exports.up = async function (knex) {
  await knex.schema.createTable('notification_reads', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('notification_id').notNullable().references('id').inTable('notifications').onDelete('CASCADE');
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.unique(['notification_id', 'user_id']);
    table.timestamp('read_at').defaultTo(knex.fn.now());
    table.index('user_id');
  });
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('notification_reads');
};
exports.up = async function (knex) {
  await knex.schema.createTable('community_post_likes', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('post_id').notNullable().references('id').inTable('community_posts').onDelete('CASCADE');
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.unique(['post_id', 'user_id']);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index('user_id');
  });
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('community_post_likes');
};
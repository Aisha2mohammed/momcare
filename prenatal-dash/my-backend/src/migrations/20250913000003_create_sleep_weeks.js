exports.up = async function (knex) {
  await knex.schema.createTable('sleep_weeks', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.integer('trimester').notNullable();
    table.integer('month').notNullable();
    table.integer('week').notNullable();
    table.text('why_important_en');
    table.text('why_important_am');
    table.text('why_important_or');
    table.text('why_important_so');
    table.text('sleeping_tips_en');
    table.text('sleeping_tips_am');
    table.text('sleeping_tips_or');
    table.text('sleeping_tips_so');
    table.boolean('is_published').defaultTo(false);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.unique(['trimester', 'month', 'week']);
    table.index(['trimester', 'month', 'week']);
  });

  // sleep_tips already exists from the old schema
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('sleep_weeks');
};
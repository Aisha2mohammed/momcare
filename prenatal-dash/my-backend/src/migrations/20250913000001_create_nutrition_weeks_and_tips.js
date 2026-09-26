exports.up = async function (knex) {
  await knex.schema.createTable('nutrition_weeks', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.integer('trimester').notNullable();
    table.integer('month').notNullable();
    table.integer('week').notNullable();
    table.text('why_important_en');
    table.text('why_important_am');
    table.text('why_important_or');
    table.text('why_important_so');
    table.text('hydration_en');
    table.text('hydration_am');
    table.text('hydration_or');
    table.text('hydration_so');
    table.boolean('is_published').defaultTo(false);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.unique(['trimester', 'month', 'week']);
    table.index(['trimester', 'month', 'week']);
  });

  await knex.schema.createTable('nutrition_tips', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('type', 20).defaultTo('eat');
    table.uuid('nutrition_week_id').references('id').inTable('nutrition_weeks').onDelete('SET NULL');
    table.string('image_url', 500);
    table.string('title_en', 500);
    table.string('title_am', 500);
    table.string('title_or', 500);
    table.string('title_so', 500);
    table.text('description_en');
    table.text('description_am');
    table.text('description_or');
    table.text('description_so');
    table.string('description_label_en', 500);
    table.string('description_label_am', 500);
    table.string('description_label_or', 500);
    table.string('description_label_so', 500);
    table.string('description_value_en', 500);
    table.string('description_value_am', 500);
    table.string('description_value_or', 500);
    table.string('description_value_so', 500);
    table.text('why_important_en');
    table.text('why_important_am');
    table.text('why_important_or');
    table.text('why_important_so');
    table.jsonb('health_tips').defaultTo('[]');
    table.jsonb('list_food').defaultTo('[]');
    table.boolean('is_published').defaultTo(false);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.index('nutrition_week_id');
    table.index('type');
  });
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('nutrition_tips');
  await knex.schema.dropTableIfExists('nutrition_weeks');
};
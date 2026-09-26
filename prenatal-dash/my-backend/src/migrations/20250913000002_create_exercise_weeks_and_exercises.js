exports.up = async function (knex) {
  await knex.schema.createTable('exercise_weeks', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.integer('trimester').notNullable();
    table.integer('month').notNullable();
    table.integer('week').notNullable();
    table.text('why_important_en');
    table.text('why_important_am');
    table.text('why_important_or');
    table.text('why_important_so');
    table.text('exercise_tips_en');
    table.text('exercise_tips_am');
    table.text('exercise_tips_or');
    table.text('exercise_tips_so');
    table.boolean('is_published').defaultTo(false);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.unique(['trimester', 'month', 'week']);
    table.index(['trimester', 'month', 'week']);
  });

  await knex.schema.createTable('exercises', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.integer('trimester').notNullable();
    table.string('category', 100).defaultTo('other');
    table.integer('duration_minutes');
    table.string('image_url', 500);
    table.string('video_url', 500);
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
    table.jsonb('list_of_exercise').defaultTo('[]');
    table.boolean('is_published').defaultTo(true);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.index('trimester');
    table.index('category');
  });
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('exercises');
  await knex.schema.dropTableIfExists('exercise_weeks');
};
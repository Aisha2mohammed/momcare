// Migration: Add advanced multilingual fields and weekly structures for sleep and exercise
// Run: npx knex migrate:latest

exports.up = async function (knex) {
  await knex.schema.alterTable('sleep_tips', (table) => {
    table.integer('week').nullable();
    table.integer('month').nullable();
    table.string('type', 50).defaultTo('generic');
    table.string('title_so', 500).nullable();
    table.text('description_so').nullable();
    table.text('why_important_am').nullable();
    table.text('why_important_or').nullable();
    table.text('why_important_en').nullable();
    table.text('why_important_so').nullable();
    table.text('tips_am').nullable();
    table.text('tips_or').nullable();
    table.text('tips_en').nullable();
    table.text('tips_so').nullable();
    table.jsonb('sections_json').nullable();
  });

  await knex.schema.alterTable('exercise_content', (table) => {
    table.integer('week').nullable();
    table.integer('month').nullable();
    table.string('type', 50).defaultTo('generic');
    table.string('name_so', 500).nullable();
    table.text('safety_notes_so').nullable();
    table.text('why_important_am').nullable();
    table.text('why_important_or').nullable();
    table.text('why_important_en').nullable();
    table.text('why_important_so').nullable();
    table.text('tips_am').nullable();
    table.text('tips_or').nullable();
    table.text('tips_en').nullable();
    table.text('tips_so').nullable();
    table.jsonb('sections_json').nullable();
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('sleep_tips', (table) => {
    table.dropColumn('week');
    table.dropColumn('month');
    table.dropColumn('type');
    table.dropColumn('title_so');
    table.dropColumn('description_so');
    table.dropColumn('why_important_am');
    table.dropColumn('why_important_or');
    table.dropColumn('why_important_en');
    table.dropColumn('why_important_so');
    table.dropColumn('tips_am');
    table.dropColumn('tips_or');
    table.dropColumn('tips_en');
    table.dropColumn('tips_so');
    table.dropColumn('sections_json');
  });

  await knex.schema.alterTable('exercise_content', (table) => {
    table.dropColumn('week');
    table.dropColumn('month');
    table.dropColumn('type');
    table.dropColumn('name_so');
    table.dropColumn('safety_notes_so');
    table.dropColumn('why_important_am');
    table.dropColumn('why_important_or');
    table.dropColumn('why_important_en');
    table.dropColumn('why_important_so');
    table.dropColumn('tips_am');
    table.dropColumn('tips_or');
    table.dropColumn('tips_en');
    table.dropColumn('tips_so');
    table.dropColumn('sections_json');
  });
};
